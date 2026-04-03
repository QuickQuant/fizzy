class Boards::PipelineSetupsController < ApplicationController
  include BoardScoped

  CANONICAL_COLUMN_NAMES = [
    "Evaluated Plans",
    "Pre-Roadmap",
    "Debate",
    "Pre-Gauntlet",
    "Gauntlet",
    "Reconciliation",
    "Finalization",
    "New Todo",
    "Review",
    "Untested",
    "Passed Test",
    "Failed Review",
    "Completed-Unmapped",
    "Completed-Mapped",
    "Cross-Project"
  ].freeze

  REQUIRED_TAG_TITLES = %w[ blocked legacy integration-sweep ].freeze

  before_action :ensure_bearer_token
  before_action :ensure_permission_to_admin_board

  def create
    columns = []
    tags = []

    Board.transaction do
      columns = synchronize_columns
      tags = synchronize_tags
    end

    render json: {
      columns: columns.map { |column| serialize_column(column) },
      tags: tags.map { |tag| serialize_tag(tag) }
    }
  end

  private
    def ensure_bearer_token
      head :unauthorized unless request.authorization.to_s.start_with?("Bearer ")
    end

    def synchronize_columns
      existing_columns = @board.columns.sorted.index_by(&:name)

      CANONICAL_COLUMN_NAMES.map.with_index(1) do |name, position|
        column = existing_columns[name] || @board.columns.create!(name: name)
        column.update_column(:position, position) unless column.position == position
        column
      end
    end

    def synchronize_tags
      REQUIRED_TAG_TITLES.map do |title|
        @board.account.tags.find_or_create_by!(title: title)
      end.sort_by(&:title)
    end

    def serialize_column(column)
      {
        id: column.id,
        name: column.name
      }
    end

    def serialize_tag(tag)
      {
        id: tag.id,
        title: tag.title
      }
    end
end
