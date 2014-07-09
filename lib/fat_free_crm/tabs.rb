# Copyright (c) 2008-2013 Michael Dvorkin and contributors.
#
# Fat Free CRM is freely distributable under the terms of MIT license.
# See MIT-LICENSE file or http://www.opensource.org/licenses/mit-license.php
#------------------------------------------------------------------------------
module FatFreeCRM
  class Tabs
    class << self
      def main_with_projects
        @@main ||= begin
          tabs = main_without_projects

          if Setting[:projects] && (tab = Setting[:projects][:tab])
            index = tabs.find_index { |v| v[:text] == :tab_tasks }
            index > 0 ? tabs.insert(index + 1, tab) : tabs << tab
          end

          tabs
        end
      end

      alias_method_chain :main, :projects
    end
  end
end
