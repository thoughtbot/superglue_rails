import { createSlice } from "@reduxjs/toolkit"
import { receiveResponse , beforeVisit } from "@thoughtbot/superglue"

const initialState = {}

export const flashSlice = createSlice({
  name: "flash",
  initialState: initialState,
  reducers: {
    clearFlash(state, { payload }) {
      const key = payload
      if (!key) {
        return {}
      }

      delete state[key]

      return {
        ...state
      }
    },
    flash(state, { payload }) {
      return {
        ...state,
        ...payload
      }
    }
  },
  extraReducers: builder => {
    builder.addCase(beforeVisit, (_state, _action) => {
      return {}
    })
    builder.addCase(receiveResponse , (state, action) => {
      const { response } = action.payload

      if(response.slices) {
        return {
          ...state,
          ...response.slices.flash
        }
      } else {
        return state
      }
    })
  }
})

export const { clearFlash, flash } = flashSlice.actions
