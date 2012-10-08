class LambdaSection < ActionView::Mustache
  def cache_section
    lambda do |&text|
      @cache ||= content_tag(:p, text.call)
    end
  end

  def expensive_call
    "42"
  end
end
