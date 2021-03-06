require "test_helper"

class SupportingPageTest < ActiveSupport::TestCase
  test "should be invalid without a title" do
    supporting_page = build(:supporting_page, title: nil)
    refute supporting_page.valid?
  end

  test "should be invalid without a body" do
    supporting_page = build(:supporting_page, body: nil)
    refute supporting_page.valid?
  end

  test "should be invalid without a edition" do
    supporting_page = build(:supporting_page, edition: nil)
    refute supporting_page.valid?
  end

  test "mark parent edition as updated when supporting page is created" do
    parent_edition = create(:draft_policy)
    lock_version = parent_edition.lock_version

    supporting_page = create(:supporting_page, edition: parent_edition)

    refute_equal lock_version, parent_edition.reload.lock_version
  end

  test "mark parent edition as updated when supporting page is updated" do
    supporting_page = create(:supporting_page)
    parent_edition = supporting_page.edition
    lock_version = parent_edition.lock_version

    supporting_page.update_attributes!(title: 'New title')

    refute_equal lock_version, parent_edition.reload.lock_version
  end

  test "should set a slug from the supporting page title" do
    supporting_page = create(:supporting_page, title: 'Love all the people')
    assert_equal 'love-all-the-people', supporting_page.slug
  end

  test "should not change the slug when the title is changed" do
    supporting_page = create(:supporting_page, title: 'Love all the people')
    supporting_page.update_attributes(title: 'Hold hands')
    assert_equal 'love-all-the-people', supporting_page.slug
  end

  test "should concatenate words containing apostrophes" do
    supporting_page = create(:supporting_page, title: "Bob's bike")
    assert_equal 'bobs-bike', supporting_page.slug
  end

  test "should not be destroyable if its edition is published" do
    supporting_page = create(:supporting_page, edition: create(:published_policy))
    refute supporting_page.destroyable?
    refute supporting_page.destroy
    assert_nothing_raised { supporting_page.reload }
  end

  test "should be destroyable if its edition is not published" do
    supporting_page = create(:supporting_page, edition: create(:draft_policy))
    assert supporting_page.destroyable?
    assert supporting_page.destroy
    assert_raises(ActiveRecord::RecordNotFound) { supporting_page.reload }
  end

  test 'should return search index data suitable for Rummageable' do
    policy = create(:published_policy)
    policy_slug = policy.document.slug
    supporting_page = create(:supporting_page, title: 'Love all the people', edition: policy)

    assert_equal 'Love all the people', supporting_page.search_index["title"]
    assert_equal "/government/policies/#{policy_slug}/supporting-pages/#{supporting_page.slug}", supporting_page.search_index['link']
    assert_equal supporting_page.body, supporting_page.search_index['indexable_content']
    assert_equal 'supporting_page', supporting_page.search_index['format']
  end

  test 'should not add supporting page to search index on creating' do
    supporting_page = build(:supporting_page)

    search_index_data = stub('search index data')
    supporting_page.stubs(:search_index).returns(search_index_data)
    Rummageable.expects(:index).with(search_index_data).never

    supporting_page.save
  end

  test 'should not add supporting page to search index on updating' do
    supporting_page = create(:supporting_page)

    search_index_data = stub('search index data')
    supporting_page.stubs(:search_index).returns(search_index_data)
    Rummageable.expects(:index).with(search_index_data).never

    supporting_page.title = 'Love all the people'
    supporting_page.save
  end

  test 'should not remove supporting page from search index on destroying' do
    policy = create(:published_policy)
    supporting_page = create(:supporting_page, edition: policy)
    policy_slug = policy.document.slug

    Rummageable.expects(:delete).with("/government/policies/#{policy_slug}/supporting-pages/#{supporting_page.slug}").never
    supporting_page.destroy
  end

  test 'should return search index data for all supporting pages on published editions' do
    policy = create(:published_policy)
    draft_policy = create(:draft_policy)
    policy_slug = policy.document.slug
    create(:supporting_page, edition: policy, title: 'Love all the people', body: 'Thoughts on love and smoking.')
    create(:supporting_page, edition: policy, title: 'Dangerous', body: 'I love my job.')
    create(:supporting_page, edition: policy, title: 'Relentless', body: 'Rockers against drugs suck.')
    create(:supporting_page, edition: policy, title: 'Arizona Bay', body: 'Marketing and advertising.')
    create(:supporting_page, edition: draft_policy, title: 'Rant in E-Minor', body: 'I\'m talking to the women here.')

    results = SupportingPage.search_index

    assert_equal 4, results.length
    assert_equal({ 'title' => 'Love all the people', 'link' => "/government/policies/#{policy_slug}/supporting-pages/love-all-the-people", 'indexable_content' => 'Thoughts on love and smoking.', 'format' => 'supporting_page' }, results[0])
    assert_equal({ 'title' => 'Dangerous', 'link' => "/government/policies/#{policy_slug}/supporting-pages/dangerous", 'indexable_content' => 'I love my job.', 'format' => 'supporting_page' }, results[1])
    assert_equal({ 'title' => 'Relentless', 'link' => "/government/policies/#{policy_slug}/supporting-pages/relentless", 'indexable_content' => 'Rockers against drugs suck.', 'format' => 'supporting_page' }, results[2])
    assert_equal({ 'title' => 'Arizona Bay', 'link' => "/government/policies/#{policy_slug}/supporting-pages/arizona-bay", 'indexable_content' => 'Marketing and advertising.', 'format' => 'supporting_page' }, results[3])
  end

  test "should not change its slug when the parent policy is updated" do
    user = create(:user)
    edition = create(:published_policy, title: "Ban beards")
    supporting_page = create(:supporting_page, edition: edition, title: "Proscribed facial hair styles")
    slug = supporting_page.slug
    new_edition = edition.create_draft(user)
    new_edition.reload.submit!
    assert_equal slug, new_edition.supporting_pages.first.slug
  end
end
