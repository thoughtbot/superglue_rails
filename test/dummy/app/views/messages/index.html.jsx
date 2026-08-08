import React from 'react'
import { useContent, toFragmentRef, useFragment, unproxy, useStreamSource } from '@thoughtbot/superglue'

const isFragment = (data) => "__id" in data

const Message = ({body}) => <p>{body}</p>

const MessageFragment = ({fragment}) => {
  const {body} = useFragment(fragment)
  return <p>{body}</p>
}

export default function MessagesIndex() {
  const content = useContent()
  const {
    header,
    streamFromMessages,
  } = content

  const spotlight = useFragment(toFragmentRef('message-1'), {optional: true})
  const { connected } = useStreamSource(streamFromMessages)
  const messages = unproxy(content.messages)

  return (
    <div>
      <h1>{header}</h1>
      <div id="spotlight">
        {spotlight && spotlight.body}
      </div>

      <div id="connection_status">{connected ? 'connected' : 'connecting'}</div>
      <div id="messages">
        { messages.map((msg) => isFragment(msg) ?  <MessageFragment fragment={msg}/> : <Message {...msg}/>) }
      </div>
    </div>
  )
}
