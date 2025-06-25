import React from 'react'
import { useContent, useStreamSource, useFragment } from '@thoughtbot/superglue'

// const isFragment = (data) => "__id" in data

export default function ProfileIndex() {
  const { streamFromMessages } = useContent()
  const profile = useFragment('profile')

  useStreamSource(streamFromMessages)

  return (
    <div>
      <h1>Users::Profiles</h1>

      <div id="users_profiles">
        {profile?.name}
      </div>
    </div>
  )
}
