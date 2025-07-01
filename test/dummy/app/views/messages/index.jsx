import React from 'react'
import { useContent, useFragment, useStreamSource } from '@thoughtbot/superglue'

const isFragment = (data) => "__id" in data

const Message = ({body}) => <p>{body}</p>

const MessageFragment = ({fragment}) => {
  const [{body}] = useFragment(fragment)
  return <p>{body}</p>
}

export default function MessagesIndex() {
  const {
    header,
    streamFromMessages,
    messages: messagesFragment
  } = useContent()
  const [spotlight] = useFragment('message-1')
  const [messages] = useFragment(messagesFragment)
  useStreamSource(streamFromMessages)

  return (
    <div>
      <h1>{header}</h1>
      <div id="spotlight">
        {spotlight && spotlight.body}
      </div>

      <div id="messages">
        { messages.map((msg) => isFragment(msg) ?  <MessageFragment fragment={msg}/> : <Message {...msg}/>) }
      </div>
    </div>
  )
}
