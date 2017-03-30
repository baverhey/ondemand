# Model for view data from PBS-Ruby response.
#
# The PBS-Ruby results are much larger than this app needs them to be
# so this model extracts the necessary info to send to the user.
#
# @author Brian L. McMichael
# @version 0.0.1
class Jobstatusdata

  attr_reader :pbsid, :jobname, :username, :account, :status, :cluster, :nodes, :starttime, :walltime, :walltime_used, :submit_args, :output_path, :nodect, :ppn, :total_cpu, :queue, :cput, :mem, :vmem, :terminal_path, :fs_path, :extended_available

  # Define an object containing only necessary data to send to client.
  #
  # Object defaults to condensed data, add extended flag to initializer to include all data used by the application.
  #
  # @return [Jobstatusdata] self
  def initialize(info, cluster=OODClusters.first.id.to_s, extended=false)
    self.pbsid = info.id
    self.jobname = info.job_name
    self.username = info.job_owner
    self.account = info.accounting_id
    self.status = info.status.state
    self.cluster = cluster
    if info.status == :running || info.status == :completed
      self.nodes = node_array(info.allocated_nodes)
      self.starttime = info.dispatch_time.to_i
    end
    # TODO Find a better way to distingush whether a native parser is available. Maybe this is fine?
    self.extended_available = OODClusters[cluster].job_config[:adapter] == "torque"
    if extended
      if OODClusters[cluster].job_config[:adapter] == "torque"
        extended_data_torque(info)
      else
        extended_data_default(info)
      end
    end
    self
  end

  # Store additional data about the job. (Torque-specific)
  #
  # Parses the `native` info function for additional information about jobs on Torque systems.
  #
  # @return [Jobstatusdata] self
  def extended_data_torque(info)
    self.walltime = info.native[:Resource_List][:walltime]
    self.walltime_used = info.native.fetch(:resources_used, {})[:walltime].presence || 0
    self.submit_args = info.native[:submit_args].presence || "None"
    self.output_path = info.native[:Output_Path].to_s.split(":").second || pbs_job[:attribs][:Output_Path]
    self.nodect = info.allocated_nodes.count
    self.ppn = info.native[:Resource_List][:nodes].to_s.split("ppn=").second || 0
    self.total_cpu = self.ppn[/\d+/].to_i * self.nodect.to_i
    self.queue = info.native[:queue]
    self.cput = info.native.fetch(:resources_used, {})[:cput].presence || 0
    mem = info.native.fetch(:resources_used, {})[:mem].presence || "0 b"
    self.mem = Filesize.from(mem).pretty
    vmem = info.native.fetch(:resources_used, {})[:vmem].presence || "0 b"
    self.vmem = Filesize.from(vmem).pretty
    output_pathname = Pathname.new(self.output_path).dirname
    self.terminal_path = OodAppkit.shell.url(path: (output_pathname.writable? ? output_pathname : ENV["HOME"]))
    self.fs_path = OodAppkit.files.url(path: (output_pathname.writable? ? output_pathname : ENV["HOME"]))
    if self.status == :running || self.status == :completed
      self.nodes = node_array(info.allocated_nodes)
      self.starttime = info.dispatch_time.to_i
    end
    self
  end

  # This should not be called, but it is available as a template for building new native parsers.
  def extended_data_default(info)
    self.walltime = ''
    self.walltime_used = ''
    self.submit_args = ''
    self.output_path = ''
    self.nodect = info.allocated_nodes.count
    self.ppn = ''
    self.total_cpu = info.procs
    self.queue = info.queue_name
    self.cput = ''
    mem = "0 b"
    self.mem = Filesize.from(mem).pretty
    vmem = "0 b"
    self.vmem = Filesize.from(vmem).pretty
    output_pathname = ENV["HOME"]
    self.terminal_path = '' #OodAppkit.shell.url(path: (output_pathname.writable? ? output_pathname : ENV["HOME"]))
    self.fs_path = '' #OodAppkit.files.url(path: (output_pathname.writable? ? output_pathname : ENV["HOME"]))
    if self.status == :running || self.status == :completed
      self.nodes = node_array(info.allocated_nodes)
      self.starttime = info.dispatch_time.to_i
    end
    self
  end

  # Converts the `allocated_nodes` object array into an array of node names
  #
  # @example [#<OodCore::Job::NodeInfo:0x00000009d3ff78 @name="n0544", @procs=2>] => ['n0544']
  #
  # @param [Array<OodCore::Job::NodeInfo>]
  # @return [Array<String>] the nodes as array
  def node_array(node_info_array)
    node_info_array.map { |n| n.name }
  end

  private

    attr_writer :pbsid, :jobname, :username, :account, :status, :cluster, :nodes, :starttime, :walltime, :walltime_used, :submit_args, :output_path, :nodect, :ppn, :total_cpu, :queue, :cput, :mem, :vmem, :terminal_path, :fs_path, :extended_available

end
