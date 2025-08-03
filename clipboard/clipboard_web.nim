when not defined(wasm):
  {.error: "This module only works in wasm".}

import strutils, sets
import abstract_clipboard

import wasmrt

type WebClipboard = ref object of Clipboard

proc pbRead(pb: Clipboard, dataType: string, output: var seq[byte]): bool {.gcsafe.} =
  let pb = WebClipboard(pb)
  return false # TODO: Implement me

proc pbAvailableFormats(pb: Clipboard, o: var HashSet[string]) =
  let pb = WebClipboard(pb)
  # TODO: Implement me

proc newBlobAux(typ: cstring, data: pointer, sz: uint32): JSObj {.importwasmexpr: """
  new Blob([new Uint8Array(_nima, $1, $2)], {type: _nimsj($0)})
  """.}

proc newBlob(typ: cstring, data: openarray[byte]): JSObj {.inline.} =
  newBlobAux(typ, addr data, data.len.uint32)

proc emptyJSObject(): JSObj {.importwasmp: "{}".}

proc setProp(n: JSObj, kIsStr: bool, k: pointer, vType: uint8, v: pointer) {.importwasmexpr: """
_nimo[$0][$1?_nimsj($2):$2] = $3&1?_nimsj($4):$3&3?!!$4:$3&4?_nimo[$4]:$4
""".}

proc setProperty(n: JSObj, k: cstring, v: JSObj) {.inline.} =
  setProp(n, true, cast[pointer](k), 4, v.o)

proc writeBlobs(blbs: JSObj) {.importwasmraw: """
  navigator.clipboard.write([new ClipboardItem(_nimo[$0])])
    .catch(console.error)
  """.}

proc pbWrite(pb: Clipboard, dataType: string, data: seq[byte]) {.gcsafe.} =
  let pb = WebClipboard(pb)
  var blobType = dataType
  if blobType == "text/plain":
    blobType &= ";charset=utf-8"
  var d: pointer = nil
  let b = newBlob(blobType, data)
  let blbs = emptyJSObject()
  blbs.setProperty(dataType, b)
  writeBlobs(blbs)

proc clipboardWithName*(name: string): Clipboard =
  var res: WebClipboard
  res.writeImpl = pbWrite
  res.readImpl = pbRead
  res.availableFormatsImpl = pbAvailableFormats
  res
