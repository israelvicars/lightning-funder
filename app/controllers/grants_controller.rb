class GrantsController < ApplicationController
  def index
    @grants = Grant.all.order(id: :asc)
    
    respond_to do |format|
      format.html
      format.json { render json: @grants }
    end
  end
  
  def update
    @grant = Grant.find(params[:id])
    
    if @grant.update(grant_params)
      render json: { status: 'success', grant: @grant }
    else
      render json: { status: 'error', errors: @grant.errors.full_messages }, status: :unprocessable_entity
    end
  end
  
  def bulk_update
    results = { success: 0, errors: [] }
    
    params[:grants].each do |grant_data|
      grant = Grant.find(grant_data[:id])
      if grant.update(grant_data.except(:id).permit!)
        results[:success] += 1
      else
        results[:errors] << { id: grant.id, messages: grant.errors.full_messages }
      end
    end
    
    render json: results
  end
  
  private
  
  def grant_params
    params.require(:grant).permit(
      :funder_name, :grant_name, :status, :project_name, :fiscal_year,
      :deadline, :submission_date, :date_awarded_declined, :award_start_date,
      :award_end_date, :date_notified, :amount_requested, :amount_awarded,
      :upcoming_tasks, :portal_website, :portal_username, :portal_password,
      :funder_location, :funder_contact_info, :funder_type, :opportunity_notes,
      :funder_notes, :grant_owner
    )
  end
end
