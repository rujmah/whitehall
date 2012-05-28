require 'test_helper'

class Admin::EditionsController
  class EditionFilterTest < ActiveSupport::TestCase
    test "should filter by document type" do
      policy = create(:consultation_response)
      another_document = create(:publication)

      assert_equal [policy], EditionFilter.new(Edition, type: 'consultation_response').editions
    end

    test "should filter by document state" do
      draft_document = create(:draft_policy)
      document_in_other_state = create(:published_policy)

      assert_equal [draft_document], EditionFilter.new(Edition, state: 'draft').editions
    end

    test "should filter by document author" do
      author = create(:user)
      document = create(:policy, authors: [author])
      document_by_another_author = create(:policy)

      assert_equal [document], EditionFilter.new(Edition, author: author.to_param).editions
    end

    test "should filter by organisation" do
      organisation = create(:organisation)
      document = create(:policy, organisations: [organisation])
      document_in_no_organisation = create(:policy)
      document_in_another_organisation = create(:publication, organisations: [create(:organisation)])

      assert_equal [document], EditionFilter.new(Edition, organisation: organisation.to_param).editions
    end

    test "should filter by document type, state and author" do
      author = create(:user)
      policy = create(:draft_policy, authors: [author])
      another_document = create(:published_policy, authors: [author])

      assert_equal [policy], EditionFilter.new(Edition, type: 'policy', state: 'draft', author: author.to_param).editions
    end

    test "should filter by document type, state and organisation" do
      organisation = create(:organisation)
      policy = create(:draft_policy, organisations: [organisation])
      another_document = create(:published_policy, organisations: [organisation])

      assert_equal [policy], EditionFilter.new(Edition, type: 'policy', state: 'draft', organisation: organisation.to_param).editions
    end

    test "should return the documents ordered by most recent first" do
      older_policy = create(:draft_policy, updated_at: 3.days.ago)
      newer_policy = create(:draft_policy, updated_at: 1.minute.ago)

      assert_equal [newer_policy, older_policy], EditionFilter.new(Edition, {}).editions
    end

    test "should provide efficient access to document creators" do
      create(:policy)
      create(:publication)
      create(:speech)
      create(:consultation)

      query_count = count_queries do
        editions = EditionFilter.new(Edition).editions
        editions.each { |d| d.creator.name }
      end

      expected_queries = [:query_for_all_documents, :query_for_all_document_authors, :query_for_all_users]
      assert_equal expected_queries.length, query_count
    end
  end
end

class Admin::EditionsControllerTest < ActionController::TestCase
  setup do
    login_as :policy_writer
  end

  should_be_an_admin_controller

  test 'should pass filter parameters to a document filter' do
    stub_filter = stub('document filter', editions: [])
    Admin::EditionsController::EditionFilter.expects(:new).with(anything, {"state" => "draft", "type" => "policy"}).returns(stub_filter)

    get :index, state: :draft, type: :policy
  end

  test 'should strip out any invalid states passed as parameters' do
    stub_filter = stub('document filter', editions: [])
    Admin::EditionsController::EditionFilter.expects(:new).with(anything, {"type" => "policy"}).returns(stub_filter)

    get :index, state: :haxxor_method, type: :policy
  end

  test 'should distinguish between document types when viewing the list of documents' do
    policy = create(:draft_policy)
    publication = create(:draft_publication)
    stub_filter = stub('document filter', editions: [policy, publication])
    Admin::EditionsController::EditionFilter.stubs(:new).returns(stub_filter)

    get :index, state: :draft

    assert_select_object(policy) { assert_select ".type", text: "Policy" }
    assert_select_object(publication) { assert_select ".type", text: "Publication" }
  end

  test 'submitting should set submitted on the document' do
    draft_document = create(:draft_policy)
    post :submit, id: draft_document

    assert draft_document.reload.submitted?
  end

  test 'submitting should redirect back to show page' do
    draft_document = create(:draft_policy)
    post :submit, id: draft_document

    assert_redirected_to admin_policy_path(draft_document)
    assert_equal "Your document has been submitted for review by a second pair of eyes", flash[:notice]
  end

  test "revising the published document should create a new draft document" do
    published_document = create(:published_policy)
    Edition.stubs(:find).returns(published_document)
    draft_document = create(:draft_policy)
    published_document.expects(:create_draft).with(current_user).returns(draft_document)

    post :revise, id: published_document
  end

  test "revising a published document redirects to edit for the new draft" do
    published_document = create(:published_policy)

    post :revise, id: published_document

    draft_document = Edition.last
    assert_redirected_to edit_admin_policy_path(draft_document.reload)
  end

  test "failing to revise an document should redirect to the existing draft" do
    published_document = create(:published_policy)
    existing_draft = create(:draft_policy, doc_identity: published_document.doc_identity)

    post :revise, id: published_document

    assert_redirected_to edit_admin_policy_path(existing_draft)
    assert_equal "There is already an active draft edition for this document", flash[:alert]
  end

  test "failing to revise an document should redirect to the existing submitted document" do
    published_document = create(:published_policy)
    existing_submitted = create(:submitted_policy, doc_identity: published_document.doc_identity)

    post :revise, id: published_document

    assert_redirected_to edit_admin_policy_path(existing_submitted)
    assert_equal "There is already an active submitted edition for this document", flash[:alert]
  end

  test "failing to revise an document should redirect to the existing rejected document" do
    published_document = create(:published_publication)
    existing_rejected = create(:rejected_publication, doc_identity: published_document.doc_identity)

    post :revise, id: published_document

    assert_redirected_to edit_admin_publication_path(existing_rejected)
    assert_equal "There is already an active rejected edition for this document", flash[:alert]
  end

  test "rejecting the document should mark it as rejected" do
    submitted_document = create(:submitted_policy)

    post :reject, id: submitted_document

    assert submitted_document.reload.rejected?
  end

  test "rejecting the document should redirect to create a new editorial remark to explain why" do
    submitted_document = create(:submitted_policy)

    post :reject, id: submitted_document
    assert_redirected_to new_admin_document_editorial_remark_path(submitted_document)
  end

  test "should remember standard filter options" do
    get :index, state: :draft, type: 'consultation'
    assert_equal 'consultation', session[:document_filters][:type]
  end

  test "should remember author filter options" do
    get :index, state: :draft, author: current_user
    assert_equal current_user.to_param, session[:document_filters][:author]
  end

  test "should remember organisation filter options" do
    organisation = create(:organisation)
    get :index, state: :draft, organisation: organisation
    assert_equal organisation.to_param, session[:document_filters][:organisation]
  end

  test "should remember state filter options" do
    get :index, state: :draft
    assert_equal 'draft', session[:document_filters][:state]
  end

  test "index should redirect to remembered filtered options if available" do
    organisation = create(:organisation)
    session[:document_filters] = { state: :submitted, author: current_user.to_param, organisation: organisation.to_param }
    get :index
    assert_redirected_to admin_documents_path(state: :submitted, author: current_user, organisation: organisation)
  end

  test "index should redirect to submitted in my department if logged an editor has no remembered filters" do
    organisation = create(:organisation)
    editor = login_as create(:departmental_editor, organisation: organisation)
    get :index
    assert_redirected_to admin_documents_path(state: :submitted, organisation: organisation)
  end

  test "index should render a list of drafts I have written if a writer has no remembered filters" do
    writer = login_as create(:policy_writer)
    get :index
    assert_redirected_to admin_documents_path(state: :draft, author: writer)
  end

  test "index should redirect to drafts if stored filter options are not valid for route building" do
    session[:document_filters] = { action: :unknown }
    get :index
    assert_redirected_to admin_documents_path(state: :draft)
  end

  [:publication, :consultation].each do |document_type|
    test "should display a form for featuring an unfeatured #{document_type} without a featuring image" do
      document = create("published_#{document_type}")
      get :index, state: :published, type: document_type
      expected_url = send("admin_document_featuring_path", document)
      assert_select ".featured form.feature[action=#{expected_url}]" do
        refute_select "input[name=_method]"
        refute_select "input[name='document[featuring_image]']"
        assert_select "input[type=submit][value='Feature']"
      end
    end

    test "should display a form for unfeaturing a featured #{document_type} without a featuring image" do
      document = create("featured_#{document_type}")
      get :index, state: :published, type: document_type
      expected_url = send("admin_document_featuring_path", document)
      assert_select ".featured form.unfeature[action=#{expected_url}]" do
        assert_select "input[name=_method][value=delete]"
        refute_select "input[name='document[featuring_image]']"
      end
    end

    test "should not show featuring image on a featured #{document_type} because they do not allow a featuring image" do
      document = create("featured_#{document_type}")
      get :index, state: :published, type: document_type
      assert_select ".featured" do
        refute_select "img"
      end
    end
  end

  test "should display a form for featuring an unfeatured news article" do
    news_article = create(:published_news_article)
    get :index, state: :published, type: :news_article
    expected_url = send("admin_document_featuring_path", news_article)
    assert_select ".featured form.feature[action=#{expected_url}]" do
      refute_select "input[name=_method]"
      assert_select "input[type=submit][value='Feature']"
    end
  end

  test "should display a form for unfeaturing a featured news article" do
    news_article = create(:featured_news_article)
    get :index, state: :published, type: :news_article
    expected_url = send("admin_document_featuring_path", news_article)
    assert_select ".featured form.unfeature[action=#{expected_url}]" do
      assert_select "input[name=_method][value=delete]"
      assert_select "input[type=submit][value='No longer feature']"
    end
  end

  test "should not display the featured column on the 'all document' page" do
    policy = create(:draft_policy)
    refute policy.featurable?
    get :index, state: :draft
    refute_select "th", text: "Featured"
    refute_select "td.featured"
  end

  test "should not display the featured column on a filtered document page where that document isn't featureable" do
    policy = create(:draft_policy)
    refute policy.featurable?
    get :index, state: :draft, type: "policy"
    refute_select "th", text: "Featured"
    refute_select "td.featured"
  end

  test "should not show published documents as force published" do
    policy = create(:published_policy)
    get :index, state: :published, type: :policy

    assert_select_object(policy)
    refute_select "tr.force_published"
  end

  test "should show force published documents as force published" do
    policy = create(:published_policy, force_published: true)
    get :index, state: :published, type: :policy

    assert_select_object(policy)
    assert_select "tr.force_published"
  end

  test "should link to all active documents" do
    get :index, state: :draft

    assert_select "a[href='#{admin_documents_path(state: :active)}']"
  end

  test "should not display the featured column when viewing all active documents" do
    create(:published_news_article)

    get :index, state: :active, type: 'news_article'

    refute_select "th", text: "Featured"
    refute_select "td.featured"
  end

  test "should display state information when viewing all active documents" do
    draft_document = create(:draft_policy)
    submitted_document = create(:submitted_publication)
    rejected_document = create(:rejected_news_article)
    published_document = create(:published_consultation)

    get :index, state: :active

    assert_select_object(draft_document) { assert_select ".state", "Draft" }
    assert_select_object(submitted_document) { assert_select ".state", "Submitted" }
    assert_select_object(rejected_document) { assert_select ".state", "Rejected" }
    assert_select_object(published_document) { assert_select ".state", "Published" }
  end

  test "should not display state information when viewing documents of a particular state" do
    draft_document = create(:draft_policy)

    get :index, state: :draft

    assert_select_object(draft_document) { refute_select ".state" }
  end
end