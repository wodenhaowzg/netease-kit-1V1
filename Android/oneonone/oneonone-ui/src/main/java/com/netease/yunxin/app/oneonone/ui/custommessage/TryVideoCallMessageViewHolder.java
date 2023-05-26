// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

package com.netease.yunxin.app.oneonone.ui.custommessage;

import android.view.LayoutInflater;
import android.view.View;
import androidx.annotation.NonNull;
import androidx.constraintlayout.widget.ConstraintLayout;
import com.netease.yunxin.app.oneonone.ui.R;
import com.netease.yunxin.app.oneonone.ui.utils.NavUtils;
import com.netease.yunxin.kit.chatkit.ui.databinding.ChatBaseMessageViewHolderBinding;
import com.netease.yunxin.kit.chatkit.ui.model.ChatMessageBean;
import com.netease.yunxin.kit.chatkit.ui.view.message.viewholder.ChatBaseMessageViewHolder;
import com.netease.yunxin.kit.common.utils.SizeUtils;

public class TryVideoCallMessageViewHolder extends ChatBaseMessageViewHolder {
  private static final String TAG = "TryVideoCallMessageViewHolder";

  public TryVideoCallMessageViewHolder(
      @NonNull ChatBaseMessageViewHolderBinding parent, int viewType) {
    super(parent, viewType);
  }

  @Override
  public void bindData(ChatMessageBean message, ChatMessageBean lastMessage) {
    super.bindData(message, lastMessage);
    int padding = SizeUtils.dp2px(8);
    baseViewBinding.baseRoot.setPadding(0, padding, 0, padding);
    baseViewBinding.baseRoot.removeAllViews();
    View view =
        LayoutInflater.from(parent.getContext())
            .inflate(R.layout.one_on_one_chat_try_video_call_holder, null);
    baseViewBinding.baseRoot.addView(view);
    ConstraintLayout.LayoutParams layoutParams =
        (ConstraintLayout.LayoutParams) view.getLayoutParams();
    layoutParams.leftToLeft = R.id.baseRoot;
    layoutParams.rightToRight = R.id.baseRoot;
    view.setLayoutParams(layoutParams);
    currentMessage = message;
    TryVideoCallMessageAttachment attachment =
        (TryVideoCallMessageAttachment) message.getMessageData().getMessage().getAttachment();
    if (attachment == null) {
      return;
    }
    view.findViewById(R.id.call_now)
        .setOnClickListener(
            v -> NavUtils.toCallVideoPage(getContainer().getContext(), attachment.getUserInfo()));
  }
}
