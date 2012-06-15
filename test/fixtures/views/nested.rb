class Nested < ActionView::Mustache
  def categories
    [
      {
        :title => "Category A",
        :topics => [{:title => "Topic 1"}]
      },
      {
        :title => "Category B",
        :topics => []
      }
    ]
  end
end
