use "collections"

primitive Anagram
  fun apply(word: String, anagrams: Array[String]): Array[String] =>
    """
    Returns all candidates that are anagrams of, but not equal to, 'word'.
    """

    let basesorted: String val = sort_string(word)

    let rv: Array[String] = []
    for f in anagrams.values() do
      // As the tests say, if the word is identical - it's not an anagram
      if (word == f) then continue end

      if (basesorted == sort_string(f)) then
        rv.push(f)
      end
    end
    rv

  fun sort_string(word: String val): String val =>
    """
    We create a representation of each word by downcasing and sorting the
    letters.  Anagrams will have identical representations.
    """

    let a: Array[U8] val = word.lower().array()
    String.from_iso_array(recover iso Sort[Array[U8], U8](a.clone()) end)
