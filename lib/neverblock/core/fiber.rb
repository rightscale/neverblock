# Author::    Mohammad A. Ali  (mailto:oldmoe@gmail.com)
# Copyright:: Copyright (c) 2009 eSpace, Inc.
# License::   Distributes under the same terms as Ruby

require 'fiber'
require 'thread'

class NeverBlock::Fiber < Fiber

  def initialize(neverblock = true, &block)
    self[:neverblock] = neverblock
    super()
  end

  #Attribute Reference--Returns the value of a fiber-local variable, using
  #either a symbol or a string name. If the specified variable does not exist,
  #returns nil.
  def [](key)
    local_fiber_variables[key]
  end
  
  #Attribute Assignment--Sets or creates the value of a fiber-local variable,
  #using either a symbol or a string. See also Fiber#[].
  def []=(key,value)
    local_fiber_variables[key] = value
  end

  #Sending an exception instance to resume will yield the fiber
  #and then raise the exception. This is necessary to raise exceptions
  #in their correct context.
  def self.yield(*args)
    result = super
    raise result if result.is_a? Exception
    result
  end

  private

  def local_fiber_variables
    @local_fiber_variables ||= {}
  end

end

# Code that is designed to work with mutexes and threads but isn't aware of fibers
# will potentially screw up. 
class Mutex
  alias :_orig_try_lock :try_lock
  def try_lock
    acquired = _orig_try_lock
    disable_neverblock if acquired
    acquired
  end

  # sleep is mostly used by ConditionVariable
  alias :_orig_sleep :sleep
  def sleep(*args)
    restore_neverblock
    ret = _orig_sleep(*args)
    disable_neverblock
    ret
  end

  alias :_orig_lock :lock
  def lock
    ret = _orig_lock
    disable_neverblock
    ret
  end

  alias :_orig_unlock :unlock
  def unlock
    restore_neverblock
    _orig_unlock
  end

  alias :_orig_synchronize :synchronize
  def synchronize
    _orig_synchronize do
      begin
        disable_neverblock
        yield
      ensure
        restore_neverblock
      end
    end
  end

  private

  # slow, only uncomment for specs/dev
  def _dbg(title)
    call_stack = caller[2..4].map{|path| path.gsub(/.*(cache\/|gems\/)/,'')}.join("->")
    fiber_str = NB::Fiber.current[:nb_fiber_pool_idx] ||  NB::Fiber.current.object_id
    unless call_stack =~ /merb_syslog_logger.*log/ || call_stack =~ /eventmachine.*next_tick/
      $stderr.puts "DEBUG: #{title}: Mutex.lock=#{self.object_id} Fiber=#{fiber_str} Callers=#{call_stack}"
    end
  end

  # disable_neverblock disables neverblock using from using its special methods for the current
  # fiber. See the "NeverBlock.neverblocking?" function for reference. With this function returning
  # false, all neverblock overriden methods should fall back to the standard ruby versions which
  # should not switch fibers. Switching fibers in the lock/synchronize section of a mutex can
  # lead to "recursive lock" errors as the two fibers can call lock/synchronize twice in the same
  # thread. See CF-2601 for reference.
  def disable_neverblock
    if NB::Fiber.respond_to?(:current) && NB::Fiber.current.respond_to?('[]') && !instance_variable_defined?(:@neverblock_save)
      @neverblock_save = NB::Fiber.current[:neverblock]
      NB::Fiber.current[:neverblock] = false
      #_dbg('NEVERBLOCK DISABLED') if @neverblock_save
    end
  end

  # restore_neverblock undoes disable_neverblock
  def restore_neverblock
    if NB::Fiber.respond_to?(:current) && NB::Fiber.current.respond_to?('[]') && instance_variable_defined?(:@neverblock_save)
      NB::Fiber.current[:neverblock] = @neverblock_save
      remove_instance_variable(:@neverblock_save)
      #_dbg('NEVERBLOCK RESTORED') if NB::Fiber.current[:neverblock]
    end
  end
end
