open! Stdune

val exec
  :  targets:Path.Set.t
  -> context:Context.t option
  -> Action.t
  -> unit Scheduler.fiber
