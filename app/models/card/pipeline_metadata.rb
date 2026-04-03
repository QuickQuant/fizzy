module Card::PipelineMetadata
  extend ActiveSupport::Concern

  def metadata_patch(patch_hash, expected_version:)
    patch = patch_hash.deep_stringify_keys
    merged_metadata = merge_pipeline_metadata(patch)

    updated = self.class.where(id: id, metadata_version: expected_version).update_all(
      pipeline_metadata: merged_metadata,
      metadata_version: expected_version + 1
    )

    return false unless updated == 1

    reload
    true
  end

  private
    def merge_pipeline_metadata(patch)
      current_metadata = (pipeline_metadata || {}).deep_stringify_keys
      merged = current_metadata.merge(patch.except("extensions"))

      if patch.key?("extensions")
        merged["extensions"] = merge_extensions(current_metadata["extensions"], patch["extensions"])
      end

      merged
    end

    def merge_extensions(current_extensions, patch_extensions)
      return nil if patch_extensions.nil?

      merged = (current_extensions || {}).deep_stringify_keys

      patch_extensions.deep_stringify_keys.each do |key, value|
        value.nil? ? merged.delete(key) : merged[key] = value
      end

      merged
    end
end
