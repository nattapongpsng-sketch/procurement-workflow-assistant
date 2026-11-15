require "rails_helper"

RSpec.describe AuditEvent do
  let!(:event) { described_class.record(action: :create, auditable: create(:person)) }

  # Each blocked statement runs in a savepoint so the test transaction stays usable.
  def blocked(&block)
    expect { described_class.transaction(requires_new: true, &block) }
      .to raise_error(ActiveRecord::StatementInvalid, /append-only/)
  end

  describe "append-only in the database (FR-28)" do
    it "rejects UPDATE even with raw SQL" do
      blocked { described_class.connection.execute("UPDATE audit_events SET action = 'update' WHERE id = #{event.id}") }
      blocked { described_class.where(id: event.id).update_all(summary: "changed") } # skips Ruby readonly
    end

    it "rejects DELETE and TRUNCATE" do
      blocked { described_class.where(id: event.id).delete_all }
      blocked { described_class.connection.execute("TRUNCATE audit_events") }
      expect(described_class.exists?(event.id)).to be(true)
    end

    it "is read-only in Ruby once saved" do
      expect { event.update!(summary: "x") }.to raise_error(ActiveRecord::ReadOnlyRecord)
      expect { event.destroy }.to raise_error(ActiveRecord::ReadOnlyRecord)
    end
  end

  describe "Auditable" do
    let(:actor) { create(:user) }

    before do
      Current.session = Session.new(user: actor)
      Current.request_ip = "10.0.0.5"
    end

    after { Current.reset }

    it "records create, update and destroy with actor, request data and changed values" do
      person = create(:person, full_name: "สมมติ ก")
      person.update!(full_name: "สมมติ ข")
      person.destroy!

      events = described_class.for_record(person).order(:id)
      expect(events.map(&:action)).to eq(%w[create update destroy])
      expect(events.second.changes_data).to eq("full_name" => [ "สมมติ ก", "สมมติ ข" ])
      expect(events.map(&:actor)).to all(eq(actor))
      expect(events.first.metadata["ip"]).to eq("10.0.0.5")
    end

    it "never stores password digests or timestamps" do
      user = create(:user)
      user.update!(password: "another-password-99")

      changes = described_class.for_record(user).flat_map { |e| e.changes_data.keys }
      expect(changes).not_to include("password_digest", "updated_at", "created_at")
      expect(described_class.for_record(user).pluck(:action)).to eq([ "create" ])
    end

    it "rolls the change back when the audit row cannot be written" do
      person = create(:person, full_name: "เดิม")
      allow(described_class).to receive(:record).and_raise(ActiveRecord::RecordInvalid)

      expect { person.update!(full_name: "ใหม่") }.to raise_error(ActiveRecord::RecordInvalid)
      expect(person.reload.full_name).to eq("เดิม")
    end
  end
end
