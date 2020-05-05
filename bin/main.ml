let read_stdin () =
  let rec loop state =
    try
      let line = input_line stdin in
      loop (state ^ line)
    with End_of_file -> state
  in
  loop ""

let parsed = Soup.parse (read_stdin ())

let translate_attr = function
  | "viewbox" -> "viewBox"
  | "form" -> "Tea.Html2.Attributes.form"
  | ("class" | "for" | "type" | "method") as attr -> attr ^ "'"
  | other -> other

let translate_element = function
  | "form" -> "Tea.Html2.form"
  | "path" -> "Tea.Svg.path"
  | ("input" | "option" | "object" | "var") as element -> element ^ "'"
  | other -> other

let spaces i = String.make i ' '

let build_attrs e indent_width =
  let attrs =
    e
    |> Soup.fold_attributes
         (fun acc key value ->
           (spaces indent_width ^ translate_attr key ^ " \"" ^ value ^ "\"")
           :: acc)
         []
    |> List.rev
  in
  String.concat ";\n" attrs

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
               if List.length children == 0 then "[]"
               else
                 "[\n"
                 ^ String.concat "\n" (List.map (fun x -> x ^ ";") children)
                 ^ "\n" ^ indent ^ "]"
             in
             let name = translate_element (Soup.name e) in
             let open_svg, close_svg =
               if name = "svg" then ("Tea.Svg.(Tea.Svg.Attributes.(", "))")
               else ("", "")
             in
             let attrs = build_attrs e (indent_width + 2) in
             let output =
               indent ^ open_svg ^ name ^ " [\n " ^ attrs ^ "\n" ^ indent
               ^ " ] " ^ children ^ close_svg
             in
             output :: state
         | None ->
             let text = String.concat " " (Soup.trimmed_texts e) in
             if String.length text = 0 then state
             else (indent ^ "text \"" ^ text ^ "\"") :: state)
       state

let () =
  let result = convert (Soup.coerce parsed) ([], 0) in
  result |> List.iter print_endline
