class Cards::MetadataController < ApplicationController
  include CardScoped

  before_action :require_metadata_version_header

  def update
    if @card.metadata_patch(metadata_params, expected_version: expected_metadata_version)
      render "cards/show", formats: :json
    else
      render json: {
        error: "METADATA_VERSION_CONFLICT",
        expected: expected_metadata_version,
        actual: @card.reload.metadata_version
      }, status: :conflict
    end
  end

  private
    def metadata_params
      params.expect(pipeline_metadata: {}).to_h
    end

    def expected_metadata_version
      @expected_metadata_version ||= Integer(request.headers["If-Match-Metadata-Version"])
    rescue ArgumentError, TypeError
      nil
    end

    def require_metadata_version_header
      render json: { error: "IF_MATCH_METADATA_VERSION_REQUIRED" }, status: :precondition_required if expected_metadata_version.nil?
    end
end
