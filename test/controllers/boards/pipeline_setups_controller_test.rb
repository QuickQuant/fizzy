require "test_helper"

class Boards::PipelineSetupsControllerTest < ActionDispatch::IntegrationTest
  CANONICAL_COLUMN_NAMES = Boards::PipelineSetupsController::CANONICAL_COLUMN_NAMES
  REQUIRED_TAG_TITLES = Boards::PipelineSetupsController::REQUIRED_TAG_TITLES

  setup do
    sign_in_as :kevin
    @write_bearer_token = { "HTTP_AUTHORIZATION" => "Bearer #{identity_access_tokens(:davids_api_token).token}" }
    @read_bearer_token = { "HTTP_AUTHORIZATION" => "Bearer #{identity_access_tokens(:jasons_api_token).token}" }
  end

  test "create requires bearer token auth" do
    post board_pipeline_setup_path(boards(:writebook)), as: :json

    assert_response :unauthorized
  end

  test "create requires write-endowed bearer token" do
    sign_out

    post board_pipeline_setup_path(boards(:writebook)), as: :json, env: @read_bearer_token

    assert_response :unauthorized
  end

  test "create seeds canonical columns and tags in order" do
    sign_out
    board = create_pipeline_board

    assert_difference -> { board.reload.columns.count }, +15 do
      assert_difference -> { board.account.tags.where(title: REQUIRED_TAG_TITLES).count }, +3 do
        post board_pipeline_setup_path(board), as: :json, env: @write_bearer_token
      end
    end

    assert_response :success
    assert_equal CANONICAL_COLUMN_NAMES, board.reload.columns.sorted.pluck(:name)
    assert_equal REQUIRED_TAG_TITLES.sort, board.account.tags.where(title: REQUIRED_TAG_TITLES).pluck(:title).sort
    assert_equal CANONICAL_COLUMN_NAMES, @response.parsed_body["columns"].pluck("name")
    assert_equal REQUIRED_TAG_TITLES.sort, @response.parsed_body["tags"].pluck("title").sort
    assert @response.parsed_body["columns"].all? { |column| column["id"].present? }
    assert @response.parsed_body["tags"].all? { |tag| tag["id"].present? }
  end

  test "create is idempotent" do
    sign_out
    board = create_pipeline_board

    post board_pipeline_setup_path(board), as: :json, env: @write_bearer_token
    assert_response :success
    first_column_ids = @response.parsed_body["columns"].pluck("id")
    first_tag_ids = @response.parsed_body["tags"].pluck("id").sort

    assert_no_difference -> { board.reload.columns.count } do
      assert_no_difference -> { board.account.tags.where(title: REQUIRED_TAG_TITLES).count } do
        post board_pipeline_setup_path(board), as: :json, env: @write_bearer_token
      end
    end

    assert_response :success
    assert_equal first_column_ids, @response.parsed_body["columns"].pluck("id")
    assert_equal first_tag_ids, @response.parsed_body["tags"].pluck("id").sort
    assert_equal CANONICAL_COLUMN_NAMES, board.reload.columns.sorted.pluck(:name)
  end

  private
    def create_pipeline_board
      Board.create!(name: "Brainquarters pipeline", creator: users(:david), account: accounts("37s"), all_access: false)
    end
end
