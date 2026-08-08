import React from 'react'
import { useContent, useStreamSource, unproxy } from '@thoughtbot/superglue'

const Message = ({body}) => <p>{body}</p>

export default function SectionIndex() {
  const content = useContent()
  const {
    header,
    streamFromMessages,
  } = content
  const { connected } = useStreamSource(streamFromMessages)

  return (
    <div>
      <h1>{header}</h1>
      <div id="connection_status">{connected ? 'connected' : 'connecting'}</div>
      <div id="messages">
        { content.messages.map((msg) => <Message {...msg}/>) }
      </div>
    </div>
  )
}
