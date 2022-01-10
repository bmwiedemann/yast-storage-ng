# Copyright (c) [2017-2020] SUSE LLC
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

require "cwm/widget"
require "y2partitioner/widgets/configurable_blk_devices_table"
require "y2partitioner/widgets/device_table_entry"
require "y2partitioner/widgets/columns"

module Y2Partitioner
  module Widgets
    # Class to represent a tab with a list of devices used by a specific device. For example, the devices
    # used to create a RAID, the wires of a Multipath, etc.
    class UsedDevicesTab < CWM::Tab
      # Constructor
      #
      # @param device [Y2Storage::Device]
      # @param pager [CWM::TreePager]
      def initialize(device, pager)
        super()
        textdomain "storage"
        @device = device
        @pager = pager
      end

      # @macro seeAbstractWidget
      def label
        _("&Used Devices")
      end

      # @macro seeCustomWidget
      def contents
        VBox(table, buttons)
      end

      # State information of the tab
      #
      # See {Widgets::Pages::Base#state_info}
      #
      # @return [Hash]
      def state_info
        { table.widget_id => table.ui_open_items }
      end

      private

      # @return [Y2Storage::Device]
      attr_reader :device

      # Buttons to show
      #
      # Derived classes should redefine this method.
      #
      # @return [Yast::Term]
      def buttons
        @buttons ||= Empty()
      end

      # Returns a table with all devices used by the container device
      #
      # @return [ConfigurableBlkDevicesTable]
      def table
        return @table unless @table.nil?

        @table = ConfigurableBlkDevicesTable.new(entries, @pager)
        @table.show_columns(*columns)
        @table
      end

      def columns
        [
          Columns::Device,
          Columns::Size,
          Columns::Format,
          Columns::Encrypted,
          Columns::Type
        ]
      end

      # Entries to show in the table. Typically one for the device with its used
      # devices as children entries.
      #
      # @return [Array<DeviceTableEntry>]
      def entries
        [DeviceTableEntry.new(device, children: used_devices, full_names: true)]
      end

      # Devices considered as used by the device
      #
      # Derived classes should redefine this method.
      #
      # @return [Array<BlkDevice>]
      def used_devices
        []
      end
    end
  end
end
