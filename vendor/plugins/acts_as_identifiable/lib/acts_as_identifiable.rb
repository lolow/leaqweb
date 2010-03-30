module ActiveRecord #:nodoc:
  module Acts #:nodoc:
    module Identifiable
      def self.included(base)
        base.extend(ClassMethods)
      end
      
      module ClassMethods
        def acts_as_identifiable(options = {:prefix=>""})
          include ActiveRecord::Acts::Identifiable::InstanceMethods
          extend ActiveRecord::Acts::Identifiable::SingletonMethods
          define_attr_method :identifiable_prefix, options[:prefix]
        end
        def identifiable_prefix
          ""
        end
      end
      
      module SingletonMethods
        def pid(id)
          "#{identifiable_prefix}#{id}"
        end
      end
      
      module InstanceMethods
        def pid
          "#{self.class.identifiable_prefix}#{id}"
        end
      end
    end
  end
end

ActiveRecord::Base.send(:include, ActiveRecord::Acts::Identifiable)
