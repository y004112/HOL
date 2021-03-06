signature m0_progLib =
sig
   val addInstructionClass: string -> unit

   val m0_config: bool * bool -> unit
   val m0_spec: string -> Thm.thm list
   val m0_spec_hex: string -> Thm.thm list

   val set_newline: string -> unit
end
