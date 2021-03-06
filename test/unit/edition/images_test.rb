require 'test_helper'

class Edition::ImagesTest < ActiveSupport::TestCase
  include ActionDispatch::TestProcess

  test "editions can be created with multiple images" do
    edition = create(:draft_policy, images_attributes: [
      {alt_text: "Something about this image",
       caption: "Text to be visible along with the image",
       image_data_attributes: {file: fixture_file_upload('portas-review.jpg')}},
      {alt_text: "alt-text-2",
       caption: "caption-2",
       image_data_attributes: {file: fixture_file_upload('portas-review.jpg')}}
    ])

    assert_equal 2, edition.images.count
    assert_equal "Something about this image", edition.images[0].alt_text
    assert_equal "Text to be visible along with the image", edition.images[0].caption
    assert_equal "alt-text-2", edition.images[1].alt_text
    assert_equal "caption-2", edition.images[1].caption
  end

  test "#create_draft should include copies of image attributes" do
    image = create(:image)
    published_policy = create(:published_policy, images: [image])
    draft_policy = published_policy.create_draft(create(:policy_writer))

    assert draft_policy.valid?

    new_image = draft_policy.images.last
    refute_equal image, new_image
    assert_equal image.alt_text, new_image.alt_text
    assert_equal image.caption, new_image.caption
  end

  test "#create_draft should not duplicate the actual image data" do
    image = create(:image)
    published_policy = create(:published_policy, images: [image])
    draft_policy = published_policy.create_draft(create(:policy_writer))
    new_image = draft_policy.images.last

    assert_equal image.image_data_id, new_image.image_data_id
  end

  test "captions for images can be changed between versions" do
    edition = create(:published_policy, images_attributes: [
      {alt_text: "alt-text",
       caption: "original-caption",
       image_data_attributes: {file: fixture_file_upload('portas-review.jpg')}}])

    draft = edition.create_draft(create(:policy_writer))
    draft.images.first.update_attributes(caption: "new-caption")

    assert_equal "original-caption", edition.images.first.caption
  end

  test "#destroy should also remove the image" do
    image = create(:image)
    edition = create(:draft_policy, images: [image])
    edition.destroy
    refute Image.find_by_id(image.id)
  end
end
