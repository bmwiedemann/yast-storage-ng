require "storage"
require "storage/disk_size"
require "storage/refinements/disk"

module Yast
  module Storage
    # Prototype of a class to allow querying a devigraph for its elements
    #
    # The class is now used in the RSpec tests and in the proposal code but the
    # API will likely change a lot depending on the discussion on
    # https://lists.opensuse.org/yast-devel/2016-03/msg00053.html
    # Thus the lack of documentation for the concrete methods
    class DevicegraphQuery
      using Refinements::Disk

      # Free disk space below this size will be disregarded
      TINY_FREE_CHUNK = DiskSize.MiB(30)

      attr_reader :devicegraph

      def initialize(devicegraph, disk_names: nil)
        @devicegraph = devicegraph
        @disk_names = disk_names
      end

      def disks
        if @disk_names
          @disk_names.map { |disk_name| ::Storage::Disk.find(@devicegraph, disk_name) }
        else
          devicegraph.all_disks.to_a
        end
      end

      def available_size
        useful_free_spaces.map(&:size).reduce(DiskSize.zero, :+)
      end

      def useful_free_spaces
        free_spaces.select { |space| space.size >= TINY_FREE_CHUNK }
      end

      def free_spaces
        disks.reduce([]) { |sum, disk| sum + disk.free_spaces }
      end

      def partitions
        disks.reduce([]) { |sum, disk| sum + disk.all_partitions }
      end
    end
  end
end