class TaggingsController < ApplicationController
  def lookup
    render :lookup, locals: { lookup: ContentLookupForm.new }
  end

  def find_by_slug
    content_lookup = ContentLookupForm.new(lookup_params)

    if content_lookup.valid?
      redirect_to tagging_path(content_lookup.content_id)
    else
      render :lookup, locals: { lookup: content_lookup }
    end
  end

  def lookup_urls
    content_lookup = ContentLookupForm.new(base_path: params[:base_path])

    if content_lookup.valid?
      content_item = ContentItem.find!(content_lookup.content_id)

      render json: {
        base_path: content_item.base_path,
        content_id: content_item.content_id,
        title: content_item.title
      }
    else
      render json: { errors: content_lookup.errors }, status: 404
    end
  end

  def show
    content_item = ContentItem.find!(params[:content_id])

    render :show, locals: {
      tagging_update: Tagging::TaggingUpdateForm.from_content_item(content_item)
    }
  rescue ContentItem::ItemNotFoundError
    render "item_not_found", status: 404
  end

  def update
    content_item = ContentItem.find!(params[:content_id])
    publisher = Tagging::TaggingUpdatePublisher.new(content_item, params[:tagging_tagging_update_form])

    if publisher.save_to_publishing_api
      redirect_to :back, success: "Tags have been updated!"
    else
      tagging_update = Tagging::TaggingUpdateForm.from_content_item(content_item)
      tagging_update.related_item_errors = publisher.related_item_errors
      tagging_update.related_item_overrides_errors = publisher.related_item_overrides_errors
      tagging_update.update_attributes_from_form(params[:tagging_tagging_update_form])

      flash.now[:danger] = "This form contains errors. Please correct them and try again."
      render :show, locals: { tagging_update: tagging_update }
    end
  rescue GdsApi::HTTPConflict
    redirect_to :back, danger: "Somebody changed the tags before you could. Your changes have not been saved."
  end

private

  def lookup_params
    params.require(:content_lookup_form).permit(:base_path)
  rescue ActionController::ParameterMissing
    { base_path: "/#{params[:slug]}" }
  end
end
