require File.expand_path('../helper', __FILE__)

class PushTest < Service::TestCase
  include Service::PushHelpers
  alias :base_payload :payload
  attr_reader :payload

  def setup
    @payload = base_payload
  end

  def test_create_tag
    no_distinct_commits!
    payload.merge!(
      'ref' => 'refs/tags/v1.2.3',
      'created' => true
    )

    assert_equal true, tag?
    assert_equal true, created?
    assert_equal 'v1.2.3', tag_name
    assert_equal '[grit] rtomayko tagged v1.2.3 at a47fd41', summary_message
    assert_match '/commits/v1.2.3', summary_url
  end

  def test_create_tag_with_base
    no_distinct_commits!
    payload.merge!(
      'ref' => 'refs/tags/v2.3.4',
      'before' => '0'*40,
      'base_ref' => 'refs/heads/master'
    )

    assert_equal true, created?
    assert_equal '[grit] rtomayko tagged v2.3.4 at master', summary_message
  end

  def test_create_branch_with_commits
    payload.merge!(
      'ref' => 'refs/heads/new-feature',
      'created' => true
    )

    assert_equal '[grit] rtomayko created new-feature (+3 new commits)', summary_message
    assert_match '/compare/', summary_url
  end

  def test_create_branch_without_commits
    no_distinct_commits!
    payload.merge!(
      'ref' => 'refs/heads/new-feature',
      'created' => true
    )

    assert_equal '[grit] rtomayko created new-feature at a47fd41', summary_message
    assert_match '/commits/new-feature', summary_url
  end

  def test_create_branch_from_base
    one_distinct_commit!
    payload.merge!(
      'ref' => 'refs/heads/new-feature',
      'base_ref' => 'refs/heads/master',
      'created' => true
    )

    assert_equal '[grit] rtomayko created new-feature from master (+1 new commit)', summary_message
  end

  def test_force_push
    payload.merge!(
      'ref' => 'refs/heads/production',
      'forced' => true,
      'pusher' => {'name' => 'hubot'}
    )

    assert_equal '[grit] hubot force-pushed production from 4c8124f to a47fd41', summary_message
    assert_match '/commits/production', summary_url
  end

  def test_delete_branch
    payload.merge!(
      'ref' => 'refs/heads/legacy-code',
      'deleted' => true,
      'after' => '0'*40
    )

    assert_equal '[grit] rtomayko deleted legacy-code at 4c8124f', summary_message
    assert_match '/commit/4c8124f', summary_url
  end

  def test_merge_from_base
    no_distinct_commits!
    payload.merge!(
      'base_ref' => 'refs/tags/refactor'
    )

    assert_equal '[grit] rtomayko merged refactor into master', summary_message
    assert_match '/compare/', summary_url
  end

  def test_merge_without_base
    no_distinct_commits!

    assert_equal '[grit] rtomayko fast-forwarded master from 4c8124f to a47fd41', summary_message
    assert_match '/compare/', summary_url
  end

  def test_push_multiple_commits
    assert_equal '[grit] rtomayko pushed 3 new commits to master', summary_message
    assert_match '/compare/', summary_url
  end

  def test_push_one_commit
    one_distinct_commit!
    payload.merge!(
      'ref' => 'refs/heads/posix-spawn'
    )

    assert_equal '[grit] rtomayko pushed 1 new commit to posix-spawn', summary_message
    assert_match '/commit/', summary_url
  end

  def test_push_without_commits
    payload.merge!(
      'commits' => []
    )

    assert_equal '[grit] rtomayko pushed nothing', summary_message
  end

  private

  def no_distinct_commits!
    payload['commits'].map{ |c| c['distinct'] = false }
  end

  def one_distinct_commit!
    no_distinct_commits!
    payload['commits'].first['distinct'] = true
  end
end
