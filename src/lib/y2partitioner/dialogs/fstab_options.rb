# Copyright (c) [2017] SUSE LLC
#
# All Rights Reserved.
#
# This program is free software; you can redistribute it and/or modify it
# under the terms of version 2 of the GNU General Public License as published
# by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
# more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, contact SUSE LLC.
#
# To contact SUSE LLC about this file by physical or electronic mail, you may
# find current contact information at www.suse.com.

require "yast"
require "cwm/dialog"
require "y2partitioner/dialogs/popup"
require "y2partitioner/widgets/format_and_mount"

module Y2Partitioner
  module Dialogs
    # CWM Dialog to set specific fstab options for the blk_device being added
    # or edited.
    class FstabOptions < Popup
      # @param controller [Actions::Controllers::Filesystem]
      def initialize(controller)
        super()
        textdomain "storage"

        @controller = controller
      end

      def title
        _("Fstab Options:")
      end

      def contents
        HBox(
          HStretch(),
          HSpacing(1),
          HVSquash(Widgets::FstabOptions.new(@controller)),
          HStretch(),
          HSpacing(1)
        )
      end
    end
  end
end
