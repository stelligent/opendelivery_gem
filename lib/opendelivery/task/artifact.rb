module OpenDelivery
  class Artifact
    def initialize
    end

    def add_timestamp(artifact, build_identifier)
      timestamp = Time.now.strftime("%Y.%m.%d.%H.%M.%S.%L")
      stamped_artifact = "#{artifact}-#{build_identifier}-#{timestamp}"
      return stamped_artifact
    end
  end
end
