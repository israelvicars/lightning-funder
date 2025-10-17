class GrantImportJob < ApplicationJob
  queue_as :default

  def perform(file_path, import_batch_id)
    import_batch = ImportBatch.find(import_batch_id)

    service = GrantImportService.new(file_path, import_batch)
    service.import

    File.delete(file_path) if File.exist?(file_path)
  rescue => e
    import_batch.update(
      status: "failed",
      error_details: { message: e.message }
    )
    raise e
  end
end
