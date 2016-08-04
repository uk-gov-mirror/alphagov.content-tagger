class TaggingSpreadsheetsController < ApplicationController
  def index
    @tagging_spreadsheets = TaggingSpreadsheet.all.newest_first
  end

  def new
    @tagging_spreadsheet = TaggingSpreadsheet.new
  end

  def create
    tagging_spreadsheet = TaggingSpreadsheet.new(tagging_spreadsheet_params)
    tagging_spreadsheet.added_by = current_user.uid
    if tagging_spreadsheet.valid?
      tagging_spreadsheet.save!
      redirect_to tagging_spreadsheets_path
    else
      @tagging_spreadsheet = tagging_spreadsheet
      render :new
    end
  end

  def show
    @tagging_spreadsheet = TaggingSpreadsheet.find(params[:id])
    if @tagging_spreadsheet.tag_mappings.count.zero?
      @fetch_errors = TagImporter::FetchRemoteData.new(@tagging_spreadsheet).run
    end
    @tag_mappings = @tagging_spreadsheet.tag_mappings.by_content_base_path.by_link_title
  end

  def import_progress
    tagging_spreadsheet = TaggingSpreadsheet.find(params[:tagging_spreadsheet_id])
    tag_mappings = tagging_spreadsheet.tag_mappings.by_content_base_path.by_link_title
    render partial: "import_progress_bar", formats: :html, locals: { tag_mappings: tag_mappings }
  end

  def refetch
    tagging_spreadsheet = TaggingSpreadsheet.find(params.fetch(:tagging_spreadsheet_id))
    tagging_spreadsheet.tag_mappings.delete_all
    redirect_to tagging_spreadsheet_path(tagging_spreadsheet)
  end

  def publish_tags
    tagging_spreadsheet = TaggingSpreadsheet.find(params.fetch(:tagging_spreadsheet_id))
    TagImporter::PublishTags.new(tagging_spreadsheet, user: current_user).run
    redirect_to tagging_spreadsheet_path(tagging_spreadsheet)
  end

  def destroy
    tagging_spreadsheet = TaggingSpreadsheet.find(params[:id])
    tagging_spreadsheet.destroy!
    redirect_to tagging_spreadsheets_path
  end

private

  def tagging_spreadsheet_params
    params.require(:tagging_spreadsheet).permit(:url)
  end
end