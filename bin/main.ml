let read_stdin () =
  let rec loop state =
    try
      let line = input_line stdin in
      loop (state ^ line)
    with End_of_file -> state
  in
  loop ""

let quoted value = "\"" ^ value ^ "\""

module S = Set.Make (String)

(* TODO: handle svg attrs *)
let unhandled_attr =
  S.of_list
    [
      "d";
      "fill";
      "stroke";
      "fill-rule";
      "clip-rule";
      "stroke-linecap";
      "stroke-linejoin";
      "stroke-width";
      "viewbox";
      "xmlns";
    ]

let is_unhandled_attr attr = unhandled_attr |> S.mem attr
let is_numeric_attr attr = attr = "tabindex"

let translate_attr key value =
  let key, maybe_value =
    match key with
    | ("class" | "for" | "type" | "method") as attr -> (attr ^ "_", None)
    | attr
      when attr |> String.starts_with ~prefix:"aria-" || is_unhandled_attr attr
      ->
        if value = "true" || value = "false" then
          (Format.sprintf "bool_attr \"%s\"" attr, Some value)
        else (Format.sprintf "string_attr \"%s\"" attr, None)
    | other -> (other, None)
  in
  let value =
    match maybe_value with
    | Some value -> value
    | None ->
        if is_numeric_attr key then
          (* adding parens to handle negative numbers and letting ocamlforamt handle cleaning it up *)
          Format.sprintf "(%s)" value
        else quoted value
  in
  Format.sprintf "%s %s" key value

let translate_element = function
  | ("span" | "label") as tag -> Format.sprintf "Tag.%s" tag
  | "object" as element -> element ^ "_"
  | ("svg" | "path") as tag -> Format.sprintf "std_tag %s" (quoted tag)
  | other -> other

let spaces i = String.make i ' '

let build_attrs e indent_width =
  let attrs =
    e
    |> Soup.fold_attributes
         (fun acc key value ->
           (spaces indent_width ^ translate_attr key value) :: acc)
         []
    |> List.rev
  in
  String.concat ";\n" attrs

let void_tags = S.of_list [ "img"; "input" ]
let is_void_tag tag = S.mem tag void_tags

let rec convert p (state, depth) =
  p |> Soup.children
  |> Soup.fold
       (fun state e ->
         let indent_width = depth * 2 in
         let indent = spaces indent_width in
         match Soup.element e with
         | Some e ->
             let children =
               List.rev (convert (Soup.coerce e) ([], depth + 1))
             in
             let children =
               if List.length children == 0 then
                 if is_void_tag (Soup.name e) then "" else "[]"
               else
                 "[\n"
                 ^ String.concat "\n" (List.map (fun x -> x ^ ";") children)
                 ^ "\n" ^ indent ^ "]"
             in
             let name = translate_element (Soup.name e) in
             (*let open_svg, close_svg =
                 if name = "svg" then ("Tea.Svg.(Tea.Svg.Attributes.(", "))")
                 else ("", "")
               in
             *)
             let attrs = build_attrs e (indent_width + 2) in
             let output =
               indent ^ name ^ " [\n " ^ attrs ^ "\n" ^ indent ^ " ] "
               ^ children
             in
             output :: state
         | None ->
             let text = String.concat " " (Soup.trimmed_texts e) in
             if String.length text = 0 then state
             else (indent ^ "txt \"" ^ text ^ "\"") :: state)
       state

let read_url url =
  let open Curly in
  match run (Request.make ~url ~meth:`GET ()) with
  | Ok x ->
      (* Format.printf "status: %d\n" x.code; *)
      (* Format.printf "headers: %a\n" Header.pp x.headers; *)
      (* Format.printf "body: %s\n" x.body; *)
      Ok x.body
  | Error e ->
      (* Format.printf "Failed: %a" Error.pp e; *)
      Error e

let parse html =
  (*
  print_endline
    "let element = let open Dream_html in let open Tag in let open Attr in ";
    *)
  let parsed = Soup.parse html in
  convert (Soup.coerce parsed) ([], 0)

let () =
  let contents =
    if Sys.argv |> Array.length = 2 then
      let arg = Sys.argv.(1) in
      read_url arg
    else Ok (read_stdin ())
  in
  Result.map parse contents
  |> Result.fold ~ok:(List.iter print_endline) ~error:(fun e ->
         Format.printf "Failed: %a" Curly.Error.pp e;
         exit 1)
