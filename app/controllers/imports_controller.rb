class ImportsController < ApplicationController
  def new
    @import_batches = ImportBatch.order(created_at: :desc).limit(10)
  end

  def create
    uploaded_file = params[:file]

    if uploaded_file.nil?
      redirect_to new_import_path, alert: "Please select a file to upload"
      return
    end

    unless valid_file_type?(uploaded_file)
      redirect_to new_import_path, alert: "Invalid file type. Please upload an Excel file (.xlsx, .xls)"
      return
    end

    import_batch = ImportBatch.create!(
      filename: uploaded_file.original_filename,
      status: "pending"
    )

    temp_file_path = save_temp_file(uploaded_file)

    GrantImportJob.perform_later(temp_file_path, import_batch.id)

    redirect_to import_batch_path(import_batch), notice: "File uploaded successfully. Import is being processed."
  end

  def show
    @import_batch = ImportBatch.find(params[:id])
    @grants = @import_batch.grants.order(:row_number).page(params[:page]).per(25)
  end

  private

  def valid_file_type?(file)
    [ "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
     "application/vnd.ms-excel" ].include?(file.content_type) ||
    file.original_filename.match?(/\.(xlsx|xls)$/i)
  end

  def save_temp_file(uploaded_file)
    temp_dir = Rails.root.join("tmp", "imports")
    FileUtils.mkdir_p(temp_dir)

    temp_file_path = temp_dir.join("#{SecureRandom.uuid}_#{uploaded_file.original_filename}")

    File.open(temp_file_path, "wb") do |file|
      file.write(uploaded_file.read)
    end

    temp_file_path.to_s
  end
end
