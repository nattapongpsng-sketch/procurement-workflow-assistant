module PurchaseRequestFixture
  EVIDENCE = SampleCases::EVIDENCE

  def build_purchase_request_case(overrides = {}) = SampleCases.purchase_request(overrides)
end

RSpec.configure { |config| config.include PurchaseRequestFixture }
