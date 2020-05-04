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
  | ("class" | "for" | "type" | "method") as attr -> attr ^ "'"
  | other -> other

let translate_element = function
  | ("input" | "option" | "object" | "var") as element -> element ^ "'"
  | other -> other

let rec convert p (state, depth) =
  p |> Soup.children |> Soup.elements
  |> Soup.fold
       (fun state e ->
         let indent = depth * 2 in
         let spaces i = String.make i ' ' in
         let children = List.rev (convert (e |> Soup.coerce) ([], depth + 1)) in
         let children =
           if List.length children == 0 then "[]"
           else
             "[\n"
             ^ String.concat "\n" (List.map (fun x -> x ^ ";") children)
             ^ "\n" ^ spaces indent ^ "]"
         in
         let attrs =
           e
           |> Soup.fold_attributes
                (fun acc key value ->
                  ( spaces (indent + 2)
                  ^ translate_attr key ^ " \"" ^ value ^ "\"" )
                  :: acc)
                []
           |> List.rev
         in
         let attrs = String.concat ";\n" attrs in
         let output =
           spaces indent
           ^ translate_element (e |> Soup.name)
           ^ " [\n " ^ attrs ^ "\n" ^ spaces indent ^ " ] " ^ children
         in
         output :: state)
       state

let () =
  let result = convert (Soup.coerce parsed) ([], 0) in
  result |> List.iter print_endline
