# Print violation messages as comments on given GitHub pull request.
class Commenter
  def initialize(payload)
    @pull_request = PullRequest.new(payload, token)
  end

  def comment_on_violations(violations)
    violations.each do |violation|
      if commenting_policy.allowed_for?(violation)
        @pull_request.comment_on_violation(violation)
      end
    end
  end

  private

  def commenting_policy
    @commenting_policy ||= CommentingPolicy.new(@pull_request)
  end

  def token
    ENV["HOUND_GITHUB_TOKEN"]
  end
end
