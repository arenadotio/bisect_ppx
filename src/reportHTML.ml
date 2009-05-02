(*
 * This file is part of Bisect.
 * Copyright (C) 2008-2009 Xavier Clerc.
 *
 * Bisect is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 3 of the License, or
 * (at your option) any later version.
 *
 * Bisect is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *)

open ReportUtils

let css =  [
  "body {" ;
  "    background: white;" ;
  "    white-space: nowrap;" ;
  "}" ;
  "" ;
  ".footer {" ;
  "    font-size: smaller;" ;
  "    text-align: center;" ;
  "}" ;
  "" ;
  ".codeSep {" ;
  "    border: none 0;" ;
  "    border-top: 1px solid gray;" ;
  "    height: 1px;" ;
  "}" ;
  "" ;
  ".indexSep {" ;
  "    border: none 0;" ;
  "    border-top: 1px solid gray;" ;
  "    height: 1px;" ;
  "    width: 75%;" ;
  "}" ;
  "" ;
  ".lineNone { white-space: nowrap; background: white; font-family: monospace; }" ;
  ".lineAllVisited { white-space: nowrap; background: green; font-family: monospace; }" ;
  ".lineAllUnvisited { white-space: nowrap; background: red; font-family: monospace; }" ;
  ".lineMixed { white-space: nowrap; background: yellow; font-family: monospace; }" ;
  "" ;
  "table.simple {" ;
  "    border-width: 1px;" ;
  "    border-spacing: 0px;" ;
  "    border-top-style: solid;" ;
  "    border-bottom-style: solid;" ;
  "    border-color: black;" ;
  "}" ;
  "" ;
  "table.simple th {" ;
  "    border-width: 1px;" ;
  "    border-spacing: 0px;" ;
  "    border-bottom-style: solid;" ;
  "    border-color: black;" ;
  "    text-align: center;" ;
  "    font-weight: bold;" ;
  "}" ;
  "" ;
  "table.simple td {" ;
  "    border-width: 1px;" ;
  "    border-spacing: 0px;" ;
  "    border-style: none;" ;
  "}" ;
  "" ;
  "table.gauge {" ;
  "    border-width: 0px;" ;
  "    border-spacing: 0px;" ;
  "    padding: 0px;" ;
  "    border-style: none;" ;
  "    border-collapse: collapse;" ;
  "}" ;
  "" ;
  "table.gauge td {" ;
  "    border-width: 0px;" ;
  "    border-spacing: 0px;" ;
  "    padding: 0px;" ;
  "    border-style: none;" ;
  "    border-collapse: collapse;" ;
  "}" ;
  "" ;
  ".gaugeOK { background: green; }" ;
  ".gaugeKO { background: red; }" ;
  ""
]

let output_css filename =
  Common.try_out_channel
    false
    filename
    (fun channel -> output_strings css [] channel)

let html_footer =
  let now = Unix.localtime (Unix.time ()) in
  Printf.sprintf
    "Generated by <a href=\"%s\">Bisect %s</a> on %d-%02d-%02d %02d:%02d:%02d"
    url
    version
    (1900 + now.Unix.tm_year)
    (1 + now.Unix.tm_mon)
    now.Unix.tm_mday
    now.Unix.tm_hour
    now.Unix.tm_min
    now.Unix.tm_sec

let html_of_stats s =
  [ "$(tabs)<table class=\"simple\">" ;
    "$(tabs)  <tr><th>kind</th><th width=\"16px\">&nbsp;</th><th>coverage</th></tr>" ] @
  (List.map
     (fun (k, r) ->
       Printf.sprintf "$(tabs)  <tr><td>%s</td><td width=\"16px\">&nbsp;</td><td>%d / %d (%s %%)</td></tr>"
         (Common.string_of_point_kind k)
         r.ReportStat.count
         r.ReportStat.total
         (if r.ReportStat.total <> 0 then
           string_of_int ((r.ReportStat.count * 100) / r.ReportStat.total)
         else
           "-"))
     s) @
  [ "$(tabs)</table>" ]

let output_html_index verbose filename l =
  verbose "Writing index file ...";
  Common.try_out_channel
    false
    filename
    (fun channel ->
      let stats =
        List.fold_left
          (fun acc (_, _, s) -> ReportStat.add acc s)
          (ReportStat.make ())
          l in
      output_strings
        [  "<html>" ;
           "  <head>" ;
           "    <title>Bisect report</title>" ;
           "    <link rel=\"stylesheet\" type=\"text/css\" href=\"style.css\">" ;
           "  </head>" ;
           "  <body>" ;
           "    <h1>Bisect report</h1>" ;
           "    <hr class=\"indexSep\"/>" ;
           "    <center>" ;
           "    <h3>Overall statistics</h3>" ]
        []
        channel;
      output_strings
        (html_of_stats  stats)
        ["tabs", "    "]
        channel;
      output_strings
        [ "    <br/>" ;
          "    </center>" ;
          "    <hr class=\"indexSep\"/>" ;
          "    <center>" ;
          "    <br/>" ;
          "    <h3>Per-file coverage</h3>" ;
          "      <table class=\"simple\">" ;
          "        <tr>" ;
          "          <th>coverage</th>" ;
          "          <th width=\"16px\">&nbsp;</th>" ;
          "          <th>file</th>";
          "        </tr>" ]
        []
        channel;
      List.iter
        (fun (in_file, out_file, stats) ->
          let a, b = ReportStat.summarize stats in
          let x = if b = 0 then 100 else (100 * a) / b in
          let y = 100 - x in
          output_strings
            [ "        <tr>" ;
              "          <td>" ;
              "            <table class=\"gauge\">" ;
              "              <tr>" ;
              "                <td class=\"gaugeOK\" width=\"$(x)px\"/>" ;
              "                <td class=\"gaugeKO\" width=\"$(y)px\"/>" ;
              "                <td>&nbsp;$(p)%</td>" ;
              "              </tr>" ;
              "            </table>" ;
              "          </td>" ;
              "          <td width=\"16px\">&nbsp;</td>" ;
              "          <td><a href=\"$(out_file)\">$(in_file)</a></td>";
              "        </tr>" ]
            [ "x", string_of_int x ;
              "y", string_of_int y ;
              "p", (if b = 0 then "-" else string_of_int x) ;
              "out_file", out_file ;
              "in_file", in_file ]
            channel)
        l;
      output_strings
        [ "      </table>" ;
          "    </center>" ;
          "    <br/>" ;
          "    <br/>" ;
          "    <hr class=\"indexSep\"/>" ;
          "    <p class=\"footer\">$(footer)</p>" ;
          "  </body>" ;
          "</html>" ]
        ["footer", html_footer]
        channel)

let output_html verbose tab_size in_file out_file visited =
  verbose (Printf.sprintf "Processing file '%s' ..." in_file);
  let cmp_content = Common.read_points in_file in
  verbose (Printf.sprintf "... file has %d points" (List.length cmp_content));
  let len = Array.length visited in
  let stats = ReportStat.make () in
  let pts = ref (List.map
                    (fun (ofs, pt, k) ->
                      let nb = if pt < len then visited.(pt) else 0 in
                      ReportStat.update stats k (nb > 0);
                      (ofs, nb))
                    cmp_content) in
  let in_channel, out_channel = open_both in_file out_file in
  (try
    output_strings
      [ "<html>" ;
        "  <head>" ;
        "    <title>Bisect report</title>" ;
        "    <link rel=\"stylesheet\" type=\"text/css\" href=\"style.css\">" ;
        "  </head>" ;
        "  <body>" ;
        "    <h3>File: $(in_file) (<a href=\"index.html\">return to index</a>)</h3>" ;
        "    <hr class=\"codeSep\"/>" ;
        "    <h4>Statistics:</h4>" ]
      [ "in_file", in_file ]
      out_channel;
    output_strings
      (html_of_stats stats)
      [ "tabs", "    " ]
      out_channel;
    output_strings
      [ "    <hr class=\"codeSep\"/>" ;
        "    <h4>Source:</h4>" ;
        "    <code>" ]
      []
      out_channel;
    let line_no = ref 0 in
    (try
      while true do
        incr line_no;
        let start_ofs = pos_in in_channel in
        let line = input_line in_channel in
        let end_ofs = pos_in in_channel in
        let before, after = split (fun (o, _) -> o < end_ofs) !pts in
        let line' = escape_line tab_size line start_ofs before in
        let visited, unvisited =
          List.fold_left
            (fun (v, u) (_, nb) ->
              ((v || (nb > 0)), (u || (nb = 0))))
            (false, false)
            before in
        let cls = match visited, unvisited with
        | false, false -> "lineNone"
        | true, false -> "lineAllVisited"
        | false, true -> "lineAllUnvisited"
        | true, true -> "lineMixed" in
        output_strings
          [ "      <div class=\"$(cls)\">$(line_no)| $(line)</div>" ]
          [ "cls", cls ;
            "line_no", (Printf.sprintf "%06d" !line_no) ;
            "line", (if line' = "" then "&nbsp;" else line') ]
          out_channel;
        pts := after
      done
    with End_of_file -> ());
    output_strings
      [ "    </code>" ;
        "    <hr class=\"codeSep\"/>" ;
        "    <p class=\"footer\">$(html_footer)</p>" ;
        "  </body>" ;
        "</html>" ]
      [ "html_footer", html_footer ]
      out_channel;
  with e ->
    close_in_noerr in_channel;
    close_out_noerr out_channel;
    raise e);
  close_in_noerr in_channel;
  close_out_noerr out_channel;
  stats

let output verbose dir tab_size data =
  let files = Hashtbl.fold
      (fun in_file visited acc ->
        let l = List.length acc in
        let basename = Printf.sprintf "file%04d.html" l in
        let out_file = Filename.concat dir basename in
        let stats = output_html verbose tab_size in_file out_file visited in
        (in_file, basename, stats) :: acc)
      data
      [] in
  output_html_index verbose (Filename.concat dir "index.html") (List.sort compare files);
  output_css (Filename.concat dir "style.css")