class Cards::LinksController < ApplicationController
  include CardScoped

  def index
    render json: scoped_links.includes(:from_card, :to_card).map { |link| serialize_link(link) }
  end

  def create
    target = @card.account.cards.find_by!(number: link_params[:to_card_number])
    link = @card.outbound_links.find_or_create_by!(to_card: target, link_type: link_params[:link_type])

    render json: serialize_link(link), status: :created
  end

  def destroy
    @card.outbound_links.find(params[:id]).destroy!

    head :no_content
  end

  private
    def scoped_links
      links = if params[:direction] == "inbound"
        @card.inbound_links
      else
        @card.outbound_links
      end

      if params[:link_type].present?
        links.of_type(params[:link_type])
      else
        links
      end
    end

    def link_params
      params.expect(link: [ :to_card_number, :link_type ])
    end

    def serialize_link(link)
      {
        id: link.id,
        from_card_number: link.from_card.number,
        to_card_number: link.to_card.number,
        link_type: link.link_type,
        created_at: link.created_at.utc
      }
    end
end
