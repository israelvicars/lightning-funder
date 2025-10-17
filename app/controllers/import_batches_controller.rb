class ImportBatchesController < ApplicationController
  def show
    @import_batch = ImportBatch.find(params[:id])
  end
end
