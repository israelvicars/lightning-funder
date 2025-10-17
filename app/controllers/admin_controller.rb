class AdminController < ApplicationController
  def index
    @grant_count = Grant.count
    @import_batch_count = ImportBatch.count
  end

  def destroy_all_grants
    count = Grant.count
    Grant.destroy_all

    redirect_to admin_path, notice: "Successfully deleted #{count} grants"
  end

  def destroy_all_batches
    batch_count = ImportBatch.count
    grant_count = Grant.count

    ImportBatch.destroy_all

    redirect_to admin_path, notice: "Successfully deleted #{batch_count} import batches and #{grant_count} grants"
  end
end
