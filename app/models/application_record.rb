class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  include ActiveModelLogger::Loggable

end
