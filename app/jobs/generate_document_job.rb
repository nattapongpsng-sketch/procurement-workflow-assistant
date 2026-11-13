class GenerateDocumentJob < ApplicationJob
  queue_as :documents

  discard_on ActiveJob::DeserializationError

  def perform(generated_document)
    DocumentGenerator.call(generated_document)
  end
end
