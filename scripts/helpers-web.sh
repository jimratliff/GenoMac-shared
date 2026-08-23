#!/usr/bin/env zsh

############### Helpers: Web

function write_rendered_markdown_html_document() {
  report_start_phase_standard
  if (( $# != 3 )); then
    report_fail "Usage: write_rendered_markdown_html_document RENDERED_FRAGMENT_PATH RENDERED_PAGE_PATH DOCUMENT_TITLE"
    return 1
  fi

  local rendered_fragment_path="$1"
  local rendered_page_path="$2"
  local document_title="$3"
  local temporary_page_path

  if [[ ! -r "${rendered_fragment_path}" ]]; then
    report_fail "The rendered Markdown fragment is not readable: ${rendered_fragment_path}"
    return 1
  fi

  if [[ "${rendered_fragment_path}" == "${rendered_page_path}" ]]; then
    report_fail "The rendered fragment and completed HTML document cannot use the same path."
    return 1
  fi

  temporary_page_path="$(
    mktemp "${rendered_page_path}.XXXXXX"
  )" || {
    report_fail "Could not create a temporary HTML document."
    return 1
  }

  if ! {
    print_rendered_markdown_html_document_opening \
      "${document_title}" &&
      command cat "${rendered_fragment_path}" &&
      print_rendered_markdown_html_document_closing
  } >"${temporary_page_path}"; then
    command rm -f "${temporary_page_path}"

    report_fail "Couldn’t construct the rendered Markdown HTML document."
    return 1
  fi

  if ! command mv -f \
    "${temporary_page_path}" \
    "${rendered_page_path}"; then
    command rm -f "${temporary_page_path}"

    report_fail "Couldn’t save the rendered Markdown HTML document."
    return 1
  fi
  report_end_phase_standard
  return 0
}

function print_rendered_markdown_html_document_opening() {
  report_start_phase_standard
  local document_title="$1"

  printf '%s\n' \
    '<!doctype html>' \
    '<html lang="en">' \
    '<head>' \
    '  <meta charset="utf-8">' \
    '  <meta name="viewport" content="width=device-width, initial-scale=1">' \
    "  <title>${document_title}</title>" \
    '  <style>' \
    '  body {' \
    '    box-sizing: border-box;' \
    '    max-width: 900px;' \
    '    margin: 40px auto;' \
    '    padding: 0 24px;' \
    '    color: #1f2328;' \
    '    font: 16px/1.5 -apple-system, BlinkMacSystemFont, sans-serif;' \
    '  }' \
    '  table { border-collapse: collapse; }' \
    '  th, td {' \
    '    padding: 6px 13px;' \
    '    border: 1px solid #d0d7de;' \
    '  }' \
    '  code {' \
    '    padding: 0.2em 0.4em;' \
    '    background: #f6f8fa;' \
    '    border-radius: 4px;' \
    '  }' \
    '  </style>' \
    '</head>' \
    '<body>'
    
  report_end_phase_standard
}

function print_rendered_markdown_html_document_closing() {
  report_start_phase_standard
  printf '%s\n' \
    '</body>' \
    '</html>'
    
  report_end_phase_standard
}
