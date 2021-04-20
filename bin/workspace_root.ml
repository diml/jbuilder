open Stdune
open Dune_engine
open Dune_rules

module Kind = struct
  type t =
    | Explicit
    | Dune_workspace
    | Dune_project
    | Cwd

  let priority = function
    | Explicit -> 0
    | Dune_workspace -> 1
    | Dune_project -> 2
    | Cwd -> 3

  let of_dir_contents files =
    if String.Set.mem files Workspace.filename then
      Some Dune_workspace
    else if String.Set.mem files Dune_project.filename then
      Some Dune_project
    else
      None
end

type t =
  { dir : string
  ; to_cwd : string list
  ; reach_from_root_prefix : string
  ; kind : Kind.t
  }

let make kind dir = { kind; dir; to_cwd = []; reach_from_root_prefix = "" }

let find () =
  let cwd = Sys.getcwd () in
  let rec loop counter ~candidate ~to_cwd dir =
    match Sys.readdir dir with
    | exception Sys_error msg ->
      User_warning.emit
        [ Pp.textf
            "Unable to read directory %s. Will not look for root in parent \
             directories."
            dir
        ; Pp.textf "Reason: %s" msg
        ; Pp.text
            "To remove this warning, set your root explicitly using --root."
        ];
      candidate
    | files ->
      let files = String.Set.of_list (Array.to_list files) in
      let candidate =
        match Kind.of_dir_contents files with
        | Some kind when Kind.priority kind <= Kind.priority candidate.kind ->
          { kind
          ; dir
          ; to_cwd
          ; (* This field is computed at the end *) reach_from_root_prefix = ""
          }
        | _ -> candidate
      in
      cont counter ~candidate dir ~to_cwd
  and cont counter ~candidate ~to_cwd dir =
    if counter > String.length cwd then
      candidate
    else
      let parent = Filename.dirname dir in
      if parent = dir then
        candidate
      else
        let base = Filename.basename dir in
        loop (counter + 1) parent ~candidate ~to_cwd:(base :: to_cwd)
  in
  let t =
    loop 0 ~to_cwd:[] cwd
      ~candidate:
        { kind = Cwd; dir = cwd; to_cwd = []; reach_from_root_prefix = "" }
  in
  { t with
    reach_from_root_prefix =
      String.concat ~sep:"" (List.map t.to_cwd ~f:(sprintf "%s/"))
  }

let create ~specified_by_user =
  match specified_by_user with
  | Some dn -> make Explicit dn
  | None ->
    if Dune_util.Config.inside_dune then
      make Cwd "."
    else
      find ()
