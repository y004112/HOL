signature arm_progLib =
sig
   val addInstructionClass: string -> unit

   val arm_config: string -> unit
   val arm_spec: string -> Thm.thm list
   val arm_spec_hex: string -> Thm.thm list

   val loadSpecs: Thm.thm -> unit
   val saveSpecs: string -> Thm.thm

   val set_newline: string -> unit
end
