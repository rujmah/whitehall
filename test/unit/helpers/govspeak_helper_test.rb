# encoding: UTF-8
require 'test_helper'

class GovspeakHelperTest < ActionView::TestCase
  include Admin::EditionRoutesHelper
  include PublicDocumentRoutesHelper

  setup do
    @request  = ActionController::TestRequest.new
    ActionController::Base.default_url_options = {}
  end
  attr_reader :request

  test "should wrap admin output with a govspeak class" do
    html = govspeak_to_admin_html("govspeak-text")
    assert_equal %{<div class="govspeak">\n<p>govspeak-text</p>\n</div>}, html.strip
  end

  test "should mark the admin govspeak output as html safe" do
    html = govspeak_to_admin_html("govspeak-text")
    assert html.html_safe?
  end

  test "should not alter urls to other sites in the admin preview" do
    html = govspeak_to_admin_html("no [change](http://external.example.com/page.html)")
    assert_govspeak %{<p>no <a href="http://external.example.com/page.html">change</a></p>}, html
  end

  test "should not alter urls to other sites" do
    html = govspeak_to_html("no [change](http://external.example.com/page.html)")
    assert_govspeak %{<p>no <a href="http://external.example.com/page.html">change</a></p>}, html
  end

  test "should not alter mailto urls in the admin preview" do
    html = govspeak_to_admin_html("no [change](mailto:dave@example.com)")
    assert_govspeak %{<p>no <a href="mailto:dave@example.com">change</a></p>}, html
  end

  test "should not alter mailto urls" do
    html = govspeak_to_html("no [change](mailto:dave@example.com)")
    assert_govspeak %{<p>no <a href="mailto:dave@example.com">change</a></p>}, html
  end

  test "should not alter invalid urls" do
    html = govspeak_to_html("no [change](not a valid url)")
    assert_govspeak %{<p>no <a href="not%20a%20valid%20url">change</a></p>}, html
  end

  test "should not alter partial urls in the admin preview" do
    html = govspeak_to_admin_html("no [change](http://)")
    assert_govspeak %{<p>no <a href="http://">change</a></p>}, html
  end

  test "should not alter partial urls" do
    html = govspeak_to_html("no [change](http://)")
    assert_govspeak %{<p>no <a href="http://">change</a></p>}, html
  end

  test "should rewrite link to draft edition in admin preview" do
    publication = create(:draft_publication)
    html = govspeak_to_admin_html("this and [that](#{admin_publication_url(publication)})")
    assert_govspeak %{<p>this and <span class="draft_link">that <sup class="explanation">(<a href="#{admin_publication_path(publication)}">draft</a>)</sup></span></p>}, html
  end

  test "should not alter unicode when replacing links" do
    publication = create(:published_publication)
    html = govspeak_to_admin_html("the [☃](#{admin_publication_url(publication)})")
    assert_govspeak %{<p>the <span class="published_link"><a href="#{public_document_url(publication)}">☃</a> <sup class="explanation">(<a href="#{admin_publication_path(publication)}">published</a>)</sup></span></p>}, html
  end

  test "should rewrite link to deleted edition in admin preview" do
    publication = create(:deleted_publication)
    html = govspeak_to_admin_html("this and [that](#{admin_publication_url(publication)})")
    assert_govspeak %{<p>this and <span class="deleted_link"><del>that</del> <sup class="explanation">(deleted)</sup></span></p>}, html
  end

  test "should rewrite link to missing edition in admin preview" do
    html = govspeak_to_admin_html("this and [that](#{admin_publication_url('missing-id')})")
    assert_govspeak %{<p>this and <span class="deleted_link"><del>that</del> <sup class="explanation">(deleted)</sup></span></p>}, html
  end

  test "should rewrite link to destroyed supporting page in admin preview" do
    html = govspeak_to_admin_html("this and [that](#{admin_edition_supporting_page_url("doesnt-exist", "missing-id")})")
    assert_govspeak %{<p>this and <span class="deleted_link"><del>that</del> <sup class="explanation">(deleted)</sup></span></p>}, html
  end

  test "should rewrite link to published edition in admin preview" do
    publication = create(:published_publication)
    html = govspeak_to_admin_html("this and [that](#{admin_publication_url(publication)})")
    assert_govspeak %{<p>this and <span class="published_link"><a href="#{public_document_url(publication)}">that</a> <sup class="explanation">(<a href="#{admin_publication_path(publication)}">published</a>)</sup></span></p>}, html
  end

  test "should rewrite link to published edition with a newer draft in admin preview" do
    publication = create(:published_publication)
    new_draft = publication.create_draft(create(:policy_writer))
    html = govspeak_to_admin_html("this and [that](#{admin_publication_url(publication)})")
    assert_govspeak %{<p>this and <span class="draft_link"><a href="#{public_document_url(publication)}">that</a> <sup class="explanation">(<a href="#{admin_publication_path(new_draft)}">draft</a>)</sup></span></p>}, html
  end

  test "should rewrite link to archived edition with a newer published edition in admin preview" do
    publication = create(:published_publication)
    writer = create(:policy_writer)
    editor = create(:departmental_editor)
    new_edition = publication.create_draft(writer)
    new_edition.change_note = "change-note"
    new_edition.save_as(writer)
    new_edition.submit!
    new_edition.publish_as(editor)
    html = govspeak_to_admin_html("this and [that](#{admin_publication_url(publication)})")
    assert_govspeak %{<p>this and <span class="published_link"><a href="#{public_document_url(publication)}">that</a> <sup class="explanation">(<a href="#{admin_publication_path(new_edition)}">published</a>)</sup></span></p>}, html
  end

  test "should rewrite link to deleted edition with an older published edition in admin preview" do
    publication = create(:published_publication)
    new_draft = publication.create_draft(create(:policy_writer))
    new_draft.delete!
    deleted_edition = new_draft
    html = govspeak_to_admin_html("this and [that](#{admin_publication_url(deleted_edition)})")
    assert_govspeak %{<p>this and <span class="published_link"><a href="#{public_document_url(publication)}">that</a> <sup class="explanation">(<a href="#{admin_publication_path(publication)}">published</a>)</sup></span></p>}, html
  end

  test "should allow attached images to be embedded in admin html" do
    images = [OpenStruct.new(alt_text: "My Alt", url: "http://example.com/image.jpg")]
    html = govspeak_to_admin_html("!!1", images)
    assert_govspeak_by_css_selector '.govspeak figure.image.embedded img', html
  end

  # public govspeak helper tests

  test "should wrap output with a govspeak class" do
    html = govspeak_to_html("govspeak-text")
    assert_equal %{<div class="govspeak">\n<p>govspeak-text</p>\n</div>}, html.strip
  end

  test "should mark the govspeak output as html safe" do
    html = govspeak_to_html("govspeak-text")
    assert html.html_safe?
  end

  test "should produce UTF-8 for HTML entities" do
    html = govspeak_to_html("a ['funny'](/url) thing")
    assert_govspeak %{<p>a <a href="/url">‘funny’</a> thing</p>}, html
  end

  test "should not link to draft editions with no published edition" do
    publication = create(:draft_publication)
    html = govspeak_to_html("this and [that](#{admin_publication_url(publication)})")
    assert_govspeak "<p>this and that</p>", html
  end

  test "should not link to deleted editions with no published edition" do
    publication = create(:deleted_publication)
    html = govspeak_to_html("this and [that](#{admin_publication_url(publication)})")
    assert_govspeak "<p>this and that</p>", html
  end

  [Policy, Publication, NewsArticle, Consultation].each do |edition_class|
    test "should rewrite absolute links to admin previews of published #{edition_class.name} as their public document" do
      edition = create(:"published_#{edition_class.name.underscore}")
      html = govspeak_to_html("this and [that](http://test.host#{admin_edition_path(edition)}) yeah?")
      assert_govspeak %{<p>this and <a href="#{public_document_url(edition)}">that</a> yeah?</p>}, html
    end
  end

  test "should rewrite absolute links to admin previews of published Speeches as their public document" do
    speech = create(:published_speech)
    public_path = public_document_url(speech)
    html = govspeak_to_html("this and [that](#{admin_speech_url(speech)}) yeah?")
    assert_govspeak %{<p>this and <a href="#{public_path}">that</a> yeah?</p>}, html
  end

  test "should rewrite absolute links to admin previews of published SupportingPages as their public document" do
    policy = create(:published_policy)
    supporting_page = create(:supporting_page, edition: policy)
    html = govspeak_to_html("this and [that](#{admin_supporting_page_url(supporting_page)}) yeah?")
    assert_govspeak %{<p>this and <a href="#{public_supporting_page_path(policy, supporting_page)}">that</a> yeah?</p>}, html
  end

  test "should rewrite absolute links to old-style admin previews of published SupportingPages as their document" do
    policy = create(:published_policy)
    supporting_page = create(:supporting_page, edition: policy)
    old_style_supporting_page_url = admin_supporting_page_url(supporting_page).gsub(/editions/, "documents")
    html = govspeak_to_html("this and [that](#{old_style_supporting_page_url}) yeah?")
    assert_govspeak %{<p>this and <a href="#{public_supporting_page_path(policy, supporting_page)}">that</a> yeah?</p>}, html
  end

  test 'should rewrite admin link to an archived edition with a published edition' do
    edition = create(:published_policy)
    writer = create(:policy_writer)
    editor = create(:departmental_editor)
    new_draft = edition.create_draft(writer)
    new_draft.save_as(writer)
    new_draft.submit!
    new_draft.publish_as(editor)

    html = govspeak_to_html("this and [that](http://test.host#{admin_edition_path(edition)}) yeah?")
    assert_govspeak %{<p>this and <a href="#{public_document_url(edition)}">that</a> yeah?</p>}, html
  end

  test 'should rewrite admin link to a draft edition with a published edition' do
    edition = create(:published_policy)
    writer = create(:policy_writer)
    new_draft = edition.create_draft(writer)
    new_draft.save_as(writer)

    html = govspeak_to_html("this and [that](http://test.host#{admin_edition_path(new_draft)}) yeah?")
    assert_govspeak %{<p>this and <a href="#{public_document_url(edition)}">that</a> yeah?</p>}, html
  end

  test "should rewrite absolute links to admin previews of Speeches as their public document on preview" do
    request.host = ActionController::Base.default_url_options[:host] = "whitehall.preview.alphagov.co.uk"
    speech = create(:published_speech)
    public_url = public_document_url(speech)
    html = govspeak_to_html("this and [that](#{admin_speech_url(speech)}) yeah?")
    assert_govspeak %{<p>this and <a href="#{public_url}">that</a> yeah?</p>}, html
  end

  test "should rewrite absolute links to admin previews of Speeches as their public document on public preview" do
    request.host = "www.preview.alphagov.co.uk"
    ActionController::Base.default_url_options[:host] = "whitehall.preview.alphagov.co.uk"
    speech = create(:published_speech)
    public_url = public_document_url(speech)
    html = govspeak_to_html("this and [that](#{admin_speech_url(speech)}) yeah?")
    assert_govspeak %{<p>this and <a href="#{public_url}">that</a> yeah?</p>}, html
  end

  test "should rewrite absolute links to admin previews of SupportingPages as their public document on preview" do
    request.host = ActionController::Base.default_url_options[:host] = "whitehall.preview.alphagov.co.uk"
    policy = create(:published_policy)
    supporting_page = create(:supporting_page, edition: policy)
    html = govspeak_to_html("this and [that](#{admin_supporting_page_url(supporting_page)}) yeah?")
    assert_govspeak %{<p>this and <a href="#{public_supporting_page_url(policy, supporting_page, host: "www.preview.alphagov.co.uk")}">that</a> yeah?</p>}, html
  end

  test "should rewrite absolute links to admin previews of SupportingPages as their public document on public preview" do
    request.host ="www.preview.alphagov.co.uk"
    ActionController::Base.default_url_options[:host] = "whitehall.preview.alphagov.co.uk"
    policy = create(:published_policy)
    supporting_page = create(:supporting_page, edition: policy)
    html = govspeak_to_html("this and [that](#{admin_supporting_page_url(supporting_page)}) yeah?")
    assert_govspeak %{<p>this and <a href="#{public_supporting_page_url(policy, supporting_page, host: "www.preview.alphagov.co.uk")}">that</a> yeah?</p>}, html
  end

  test "should rewrite absolute links to admin previews of Speeches as their public document on production" do
    request.host = ActionController::Base.default_url_options[:host] = "whitehall.production.alphagov.co.uk"
    speech = create(:published_speech)
    public_url = public_document_url(speech)
    html = govspeak_to_html("this and [that](#{admin_speech_url(speech)}) yeah?")
    assert_govspeak %{<p>this and <a href="#{public_url}">that</a> yeah?</p>}, html
  end

  test "should rewrite absolute links to admin previews of Speeches as their public document on public production" do
    request.host = "www.gov.uk"
    ActionController::Base.default_url_options[:host] = "whitehall.production.alphagov.co.uk"
    speech = create(:published_speech)
    public_url = public_document_url(speech)
    html = govspeak_to_html("this and [that](#{admin_speech_url(speech)}) yeah?")
    assert_govspeak %{<p>this and <a href="#{public_url}">that</a> yeah?</p>}, html
  end

  test "should rewrite absolute links to admin previews of SupportingPages as their public document on production" do
    request.host = ActionController::Base.default_url_options[:host] = "whitehall.production.alphagov.co.uk"
    policy = create(:published_policy)
    supporting_page = create(:supporting_page, edition: policy)
    html = govspeak_to_html("this and [that](#{admin_supporting_page_url(supporting_page)}) yeah?")
    assert_govspeak %{<p>this and <a href="#{public_supporting_page_url(policy, supporting_page, host: "www.gov.uk")}">that</a> yeah?</p>}, html
  end

  test "should rewrite absolute links to admin previews of SupportingPages as their public document on public production" do
    request.host = "www.gov.uk"
    ActionController::Base.default_url_options[:host] = "whitehall.production.alphagov.co.uk"
    policy = create(:published_policy)
    supporting_page = create(:supporting_page, edition: policy)
    html = govspeak_to_html("this and [that](#{admin_supporting_page_url(supporting_page)}) yeah?")
    assert_govspeak %{<p>this and <a href="#{public_supporting_page_url(policy, supporting_page, host: "www.gov.uk")}">that</a> yeah?</p>}, html
  end

  test "should not link to SupportingPages whose editions are not published" do
    policy = create(:draft_policy)
    supporting_page = create(:supporting_page, edition: policy)
    html = govspeak_to_html("this and [that](http://test.host#{admin_supporting_page_path(supporting_page)}) yeah?")
    assert_govspeak %{<p>this and that yeah?</p>}, html
  end

  test "should allow attached images to be embedded in public html" do
    images = [OpenStruct.new(alt_text: "My Alt", url: "http://example.com/image.jpg")]
    html = govspeak_to_html("!!1", images)
    assert_govspeak_by_css_selector '.govspeak figure.image.embedded img', html
  end

  test "should only extract level two headers by default" do
    text = "# Heading 1\n\n## Heading 2\n\n### Heading 3"
    headers = govspeak_headers(text)
    assert_equal [Govspeak::Header.new("Heading 2", 2, "heading-2")], headers
  end

  test "should be able to extract header_heirarchy from level 2+3 headers" do
    text = "# Heading 1\n\n## Heading 2a\n\n### Heading 3a\n\n### Heading 3b\n\n#### Ignored heading\n\n## Heading 2b"
    headers = govspeak_header_heirarchy(text)
    assert_equal [
      {
        header: Govspeak::Header.new("Heading 2a", 2, "heading-2a"),
        children: [
          Govspeak::Header.new("Heading 3a", 3, "heading-3a"),
          Govspeak::Header.new("Heading 3b", 3, "heading-3b")
        ]
      },
      {
        header: Govspeak::Header.new("Heading 2b", 2, "heading-2b"),
        children: []
      }
    ], headers
  end

  private

  def assert_govspeak(expected, actual)
    assert_equal %{<div class="govspeak">\n#{expected}\n</div>}, actual.strip
  end

  def assert_govspeak_by_css_selector(css_selector, actual, &block)
    doc = Nokogiri::HTML::Document.new
    doc.encoding = "UTF-8"
    fragment = doc.fragment(actual.strip)
    found = fragment.css(css_selector)
    if found.size > 0
      found.instance_eval(&block) if block_given?
    else
      fail "Expected to find '#{css_selector}', but not found in '#{actual}'"
    end
  end

end
