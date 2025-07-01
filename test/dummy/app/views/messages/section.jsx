import React from 'react'
import { useContent, useFragment, useStreamSource } from '@thoughtbot/superglue'

const Message = ({body}) => <p>{body}</p>

export default function SectionIndex() {
  const {
    header,
    streamFromMessages,
    messages: messagesFragment
  } = useContent()
  const [messages] = useFragment(messagesFragment)
  useStreamSource(streamFromMessages)

  return (
    <div>
      <h1>{header}</h1>
      <div id="messages">
        { messages.map((msg) => <Message {...msg}/>) }
      </div>
    </div>
  )
}
