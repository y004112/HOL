signature mips_progLib =
sig
   val mips_config: bool -> unit
   val mips_spec: Term.term -> Thm.thm list
   val mips_spec_hex: string -> Thm.thm list
end
