module Conference::ReaderExtension
  def self.included(base)
    base.send(:has_one, :conference_subscription)
  end
end