class BuildReportJob < ApplicationJob
  MAX_COMMENTS = ENV.fetch("MAX_COMMENTS").to_i

  queue_as :medium

  def perform(build)
    @build = build
    commenter.comment_on_violations(priority_violations)
    create_success_status
    track_subscribed_build_completed
  end

  private

  attr_reader :build

  def commenter
    Commenter.new(payload)
  end

  def payload
    Payload.new(
      "number" => build.pull_request_number,
      "pull_request" => {
        "head" => {
          "sha" => build.commit_sha,
        },
      },
      "repository" => {
        "full_name" => build.repo.full_github_name,
      },
    )
  end

  def token
    ENV["HOUND_GITHUB_TOKEN"]
  end

  def violations
    build.violations
  end

  def priority_violations
    violations.take(MAX_COMMENTS)
  end

  def create_success_status
    github.create_success_status(
      payload.full_repo_name,
      payload.head_sha,
      I18n.t(:success_status, count: violation_count)
    )
  end

  def violation_count
    violations.map(&:messages_count).sum
  end

  def github
    @github ||= GithubApi.new(token)
  end

  def track_subscribed_build_completed
    if build.repo.subscription
      user = build.repo.subscription.user
      analytics = Analytics.new(user)
      analytics.track_build_completed(build.repo)
    end
  end
end
