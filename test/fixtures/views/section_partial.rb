class SectionPartial < ActionView::Mustache
  def people
    [{:name => "Josh"},
     {:name => "Chris"}]
  end
end
